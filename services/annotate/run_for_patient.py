"""
run_for_patient.py
------------------
Entry point invoked by saveChatControlSettings.jsp when chat_type='srijit'.

Usage:
    python3 run_for_patient.py <patient_id>

For every chat session found for the patient the script:
  1. Runs the annotate pipeline (run_session) to produce clinical signals.
  2. Saves the signals for that session into signal_history.
  3. Saves a row into session_history linking the session to its signal.
  4. For sessions 2+ saves a row into session_deltas capturing what changed
     compared to the previous session.

DB connection:
    Env vars ANNOTATE_DB_HOST / _PORT / _NAME / _USER / _PASS override defaults.
    Default: M-Dosthi_merged  /  root  /  Root@1234!

Reliability:
  * All writes for one session happen inside a single transaction
    (pipeline_run + signal + session_history + delta commit together),
    so a crash can never leave a session half-annotated and silently
    skipped on the next run.
  * The connection is pinged (with auto-reconnect) at the top of each
    iteration and again after the slow LLM call, before the transaction
    starts, so long pipeline runs can't kill the run via wait_timeout.
  * A failure in one session is rolled back and logged, and the loop
    continues; the script exits non-zero at the end if any session failed.
    Failed sessions are safe to re-run: the rollback means
    _already_annotated stays False for them.
Database updatation details:

    pipeline_runs (insert/update, keyed on run_id):
      run_id, conversation_id, patient_id, total_rounds, rounds,
      consensus, dataset_row, session_delta,
      longitudinal_sanity, longitudinal_output

    signal_history (insert/update, keyed on signal_id):
      signal_id, concerns, triggers, readiness, advice,
      quit_history, suicidal_ideation

    session_history (insert/update, keyed on session_id):
      session_id, pat_id, session_date, start_time,
      session_summary, signal_id

    session_deltas (insert/update, keyed on from_session_id/to_session_id;
    written only for session 2 onwards):
      pat_id, from_session_id, to_session_id,
      from_signal_id, to_signal_id, from_session_date, to_session_date,
      readiness_before, readiness_after, readiness_changed,
      concerns_before, concerns_after, new_concerns, resolved_concerns,
      persistent_concerns, concern_changed,
      triggers_before, triggers_after, new_triggers, resolved_triggers,
      persistent_triggers, trigger_changed,
      advice_before, advice_after, new_advice, continued_advice,
      dropped_advice, advice_changed,
      quit_history_before, quit_history_after, quit_history_changed,
      new_quit_attempts, cumulative_quit_history,
      relapse_detected, progress_detected, rapid_progress_detected,
      stagnation_detected, concern_shift_detected, trigger_resolved,
      clinical_summary
    """

import sys
import os
import json
import traceback
from datetime import datetime

import pymysql
import pymysql.cursors

from annotate.graph.runner import run_session
from annotate.graph.workflow import get_manager
from annotate.agents.memory.patient_memory import PatientMemory

# ---------------------------------------------------------------------------
# DB config
# ---------------------------------------------------------------------------

_DB_CONFIG = {
    "host":    os.environ.get("ANNOTATE_DB_HOST", "127.0.0.1"),
    "port":    int(os.environ.get("ANNOTATE_DB_PORT", "3306")),
    "db":      os.environ.get("ANNOTATE_DB_NAME", "M-Dosthi_merged"),
    "user":    os.environ.get("ANNOTATE_DB_USER", "root"),
    "passwd":  os.environ.get("ANNOTATE_DB_PASS", "Root@1234!"),
    "charset": "utf8mb4",
    # autocommit stays on for plain reads; per-session write blocks
    # explicitly open a transaction with conn.begin() and commit/rollback.
    "autocommit": True,
}

# Tables in M-Dosthi_merged accessed by this pipeline.
TABLES = {
    "chat_sessions":   {"access": "read",       "purpose": "list of counseling sessions for the patient"},
    "chat_messages":   {"access": "read",       "purpose": "message transcript per session"},
    "signal_history":  {"access": "read/write", "purpose": "per-session annotation signals (concerns, triggers, readiness, advice, quit history)"},
    "session_history": {"access": "read/write", "purpose": "per-session summary linking a chat session to its signal"},
    "session_deltas":  {"access": "read/write", "purpose": "session-to-session longitudinal deltas and patient profile state"},
    "pipeline_runs":   {"access": "write",      "purpose": "full pipeline run metadata (debate rounds, consensus, dataset row)"},
}


def _connect():
    return pymysql.connect(**_DB_CONFIG)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _jstr(val) -> str:
    """JSON-encode lists/dicts; pass strings/None through unchanged."""
    if isinstance(val, (list, dict)):
        return json.dumps(val)
    return val or ""


def _flag(val) -> int:
    return 1 if val else 0


def _make_signal_id(patient_id: str, session_id) -> str:
    return f"SIG_{patient_id}_{session_id}"


def _session_in_history(conn, session_id: str) -> bool:
    """Return True if session_history already has a row for this session_id."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT 1 FROM session_history WHERE session_id = %s LIMIT 1",
            (session_id,)
        )
        return cur.fetchone() is not None


def _already_annotated(conn, signal_id: str) -> bool:
    """Return True if signal_history already has a row for this signal_id."""
    with conn.cursor() as cur:
        cur.execute(
            "SELECT 1 FROM signal_history WHERE signal_id = %s LIMIT 1",
            (signal_id,)
        )
        return cur.fetchone() is not None


def _load_existing_row(conn, signal_id: str) -> dict:
    """Reconstruct a dataset_row dict from already-stored DB data."""
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT sh.session_summary, "
            "       si.concerns, si.triggers, si.readiness, si.advice, si.quit_history "
            "FROM   session_history sh "
            "LEFT JOIN signal_history si ON sh.signal_id = si.signal_id "
            "WHERE  si.signal_id = %s LIMIT 1",
            (signal_id,)
        )
        row = cur.fetchone()

    if not row:
        return {}

    def _parse(val):
        if not val:
            return []
        try:
            parsed = json.loads(val)
            return parsed if isinstance(parsed, list) else []
        except Exception:
            return []

    return {
        "all_concerns":           _parse(row.get("concerns")),
        "all_triggers":           _parse(row.get("triggers")),
        "stage_of_change":        row.get("readiness") or "unknown",
        "recommended_intervention": _parse(row.get("advice")),
        "quit_attempt_history":   row.get("quit_history") or "unknown",
        "reasoning_summary":      row.get("session_summary") or "",
    }


def _fetch_sessions(conn, patient_id: str):
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            "SELECT session_id, session_date, start_time FROM chat_sessions "
            "WHERE pat_id = %s ORDER BY session_date ASC, start_time ASC",
            (patient_id,)
        )
        return cur.fetchall()


def _fetch_all_messages(conn, session_ids: list) -> dict:
    """Return {session_id: [rows]} for all sessions in one query."""
    if not session_ids:
        return {}
    placeholders = ",".join(["%s"] * len(session_ids))
    with conn.cursor(pymysql.cursors.DictCursor) as cur:
        cur.execute(
            f"SELECT session_id, sender_type, message_content, message_sequence "
            f"FROM chat_messages WHERE session_id IN ({placeholders}) "
            f"ORDER BY session_id, message_sequence ASC",
            session_ids,
        )
        result: dict = {}
        for row in cur.fetchall():
            result.setdefault(row["session_id"], []).append(row)
    return result


def _format_chat(messages) -> str:
    return "\n".join(
        f"{(m.get('sender_type') or 'unknown').upper()}: "
        f"{(m.get('message_content') or '').strip()}"
        for m in messages
    )


# ---------------------------------------------------------------------------
# DB writes
# ---------------------------------------------------------------------------

def _save_signal(conn, signal_id: str, row: dict):
    """
    signal_history
      signal_id  PK
      concerns   → all_concerns  (JSON list)
      triggers   → all_triggers  (JSON list)
      readiness  → stage_of_change
      advice     → recommended_intervention  (JSON list)
      quit_history → quit_attempt_history
    """
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO signal_history
                (signal_id, concerns, triggers, readiness, advice, quit_history,
                 suicidal_ideation)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                concerns          = VALUES(concerns),
                triggers          = VALUES(triggers),
                readiness         = VALUES(readiness),
                advice            = VALUES(advice),
                quit_history      = VALUES(quit_history),
                suicidal_ideation = VALUES(suicidal_ideation)
        """, (
            signal_id,
            _jstr(row.get("all_concerns", [])),
            _jstr(row.get("all_triggers", [])),
            row.get("stage_of_change", "unknown"),
            _jstr(row.get("recommended_intervention", [])),
            row.get("quit_attempt_history", "unknown"),
            _flag(row.get("suicidal_ideation", False)),
        ))


def _save_session_history(
    conn,
    session_id,
    patient_id: str,
    session_date,
    start_time,
    summary: str,
    signal_id: str,
):
    """
    session_history
      session_id    PK  → chat session ID from chat_sessions
      pat_id            → patient ID
      session_date      → date of the chat session
      start_time        → datetime when the session started
      session_summary   → reasoning_summary from the pipeline
      signal_id     FK  → signal_history.signal_id
    """
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO session_history
                (session_id, pat_id, session_date, start_time, session_summary, signal_id)
            VALUES (%s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                session_summary = VALUES(session_summary),
                signal_id       = VALUES(signal_id)
        """, (
            session_id,
            patient_id,
            session_date,
            start_time or datetime.utcnow(),
            summary or "",
            signal_id,
        ))


def _save_pipeline_run(conn, data: dict) -> None:
    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO pipeline_runs (
                run_id, conversation_id, patient_id,
                total_rounds, rounds,
                consensus, dataset_row,
                session_delta, longitudinal_sanity, longitudinal_output
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                total_rounds        = VALUES(total_rounds),
                rounds              = VALUES(rounds),
                consensus           = VALUES(consensus),
                dataset_row         = VALUES(dataset_row),
                session_delta       = VALUES(session_delta),
                longitudinal_sanity = VALUES(longitudinal_sanity),
                longitudinal_output = VALUES(longitudinal_output)
        """, (
            data["run_id"],
            data["conversation_id"],
            data["patient_id"],
            data["total_rounds"],
            json.dumps(data["rounds"]),
            json.dumps(data["consensus"])           if data["consensus"]           else None,
            json.dumps(data["dataset_row"])         if data["dataset_row"]         else None,
            json.dumps(data["session_delta"])       if data["session_delta"]       else None,
            json.dumps(data["longitudinal_sanity"]) if data["longitudinal_sanity"] else None,
            json.dumps(data["longitudinal_output"]) if data["longitudinal_output"] else None,
        ))


def _save_delta(conn, patient_id: str, prev: dict, curr: dict, delta: dict):
    """
    session_deltas — one row per consecutive session pair.

    prev / curr are dicts:  { session_id, signal_id, session_date, row }
    delta is SessionDelta.model_dump() (never None when this is called).

    Field mapping
    ─────────────
    readiness_before/after  ← delta stage_before / stage_after
    readiness_changed       ← delta stage_changed
    concerns_before/after   ← prev/curr row all_concerns
    new/resolved/persistent ← delta new_concerns / resolved_concerns / persistent_concerns
    concern_changed         ← 1 if any new or resolved concerns
    (same pattern for triggers)
    advice_before/after     ← prev/curr row recommended_intervention
    new_advice              ← delta new_interventions
    continued_advice        ← delta continuing_interventions
    dropped_advice          ← delta dropped_interventions
    advice_changed          ← 1 if any new or dropped advice
    quit_history_before/after ← prev/curr row quit_attempt_history
    quit_history_changed    ← 1 if value changed
    relapse_detected        ← delta relapse_detected
    progress_detected       ← 1 if stage_direction in (progress, recovery)
    stagnation_detected     ← delta stagnation_detected
    clinical_summary        ← delta clinical_summary

    """
    d        = delta
    prev_row = prev["row"]
    curr_row = curr["row"]
    stage_dir = d.get("stage_direction", "unknown")

    quit_before = prev_row.get("quit_attempt_history", "unknown")
    quit_after  = curr_row.get("quit_attempt_history", "unknown")

    new_concerns   = d.get("new_concerns", [])
    res_concerns   = d.get("resolved_concerns", [])
    new_triggers   = d.get("new_triggers", [])
    res_triggers   = d.get("resolved_triggers", [])
    new_advice     = d.get("new_interventions", [])
    dropped_advice = d.get("dropped_interventions", [])

    with conn.cursor() as cur:
        cur.execute("""
            INSERT INTO session_deltas (
                pat_id,
                from_session_id,   to_session_id,
                from_signal_id,    to_signal_id,
                from_session_date, to_session_date,

                readiness_before, readiness_after, readiness_changed,

                concerns_before, concerns_after,
                new_concerns, resolved_concerns, persistent_concerns,
                concern_changed,

                triggers_before, triggers_after,
                new_triggers, resolved_triggers, persistent_triggers,
                trigger_changed,

                advice_before, advice_after,
                new_advice, continued_advice, dropped_advice,
                advice_changed,

                quit_history_before, quit_history_after, quit_history_changed,
                new_quit_attempts, cumulative_quit_history,

                relapse_detected, progress_detected, rapid_progress_detected,
                stagnation_detected, concern_shift_detected, trigger_resolved,
                clinical_summary
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s,
                %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s,
                %s, %s, %s,
                %s, %s,
                %s, %s, %s, %s, %s, %s, %s
            )
            ON DUPLICATE KEY UPDATE
                from_signal_id          = VALUES(from_signal_id),
                to_signal_id            = VALUES(to_signal_id),
                readiness_before        = VALUES(readiness_before),
                readiness_after         = VALUES(readiness_after),
                readiness_changed       = VALUES(readiness_changed),
                concerns_before         = VALUES(concerns_before),
                concerns_after          = VALUES(concerns_after),
                new_concerns            = VALUES(new_concerns),
                resolved_concerns       = VALUES(resolved_concerns),
                persistent_concerns     = VALUES(persistent_concerns),
                concern_changed         = VALUES(concern_changed),
                triggers_before         = VALUES(triggers_before),
                triggers_after          = VALUES(triggers_after),
                new_triggers            = VALUES(new_triggers),
                resolved_triggers       = VALUES(resolved_triggers),
                persistent_triggers     = VALUES(persistent_triggers),
                trigger_changed         = VALUES(trigger_changed),
                advice_before           = VALUES(advice_before),
                advice_after            = VALUES(advice_after),
                new_advice              = VALUES(new_advice),
                continued_advice        = VALUES(continued_advice),
                dropped_advice          = VALUES(dropped_advice),
                advice_changed          = VALUES(advice_changed),
                quit_history_before     = VALUES(quit_history_before),
                quit_history_after      = VALUES(quit_history_after),
                quit_history_changed    = VALUES(quit_history_changed),
                new_quit_attempts       = VALUES(new_quit_attempts),
                cumulative_quit_history = VALUES(cumulative_quit_history),
                relapse_detected        = VALUES(relapse_detected),
                progress_detected       = VALUES(progress_detected),
                rapid_progress_detected = VALUES(rapid_progress_detected),
                stagnation_detected     = VALUES(stagnation_detected),
                concern_shift_detected  = VALUES(concern_shift_detected),
                trigger_resolved        = VALUES(trigger_resolved),
                clinical_summary        = VALUES(clinical_summary)
        """, (
            patient_id,
            prev["session_id"],   curr["session_id"],
            prev["signal_id"],    curr["signal_id"],
            prev["session_date"], curr["session_date"],

            d.get("stage_before", "unknown"),
            d.get("stage_after",  "unknown"),
            _flag(d.get("stage_changed", False)),

            _jstr(prev_row.get("all_concerns", [])),
            _jstr(curr_row.get("all_concerns", [])),
            _jstr(new_concerns),
            _jstr(res_concerns),
            _jstr(d.get("persistent_concerns", [])),
            _flag(new_concerns or res_concerns),

            _jstr(prev_row.get("all_triggers", [])),
            _jstr(curr_row.get("all_triggers", [])),
            _jstr(new_triggers),
            _jstr(res_triggers),
            _jstr(d.get("persistent_triggers", [])),
            _flag(new_triggers or res_triggers),

            _jstr(prev_row.get("recommended_intervention", [])),
            _jstr(curr_row.get("recommended_intervention", [])),
            _jstr(new_advice),
            _jstr(d.get("continuing_interventions", [])),
            _jstr(dropped_advice),
            _flag(new_advice or dropped_advice),

            quit_before,
            quit_after,
            _flag(quit_before != quit_after),
            _jstr(d.get("new_quit_attempts", [])),
            d.get("cumulative_quit_history", ""),

            _flag(d.get("relapse_detected", False)),
            _flag(stage_dir in ("progress", "recovery")),
            _flag(d.get("rapid_progress_detected", False)),
            _flag(d.get("stagnation_detected", False)),
            _flag(d.get("concern_shift_detected", False)),
            _flag(d.get("trigger_resolved", False)),

            d.get("clinical_summary", ""),
        ))


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 run_for_patient.py <patient_id> [--session <session_id>]", file=sys.stderr)
        sys.exit(1)

    patient_id = sys.argv[1].strip()

    # Optional: --session <session_id> to annotate only one specific session
    target_session_id = None
    if "--session" in sys.argv:
        idx = sys.argv.index("--session")
        if idx + 1 < len(sys.argv):
            target_session_id = sys.argv[idx + 1].strip()

    if target_session_id:
        print(f"[annotate] Starting pipeline for patient: {patient_id}, session: {target_session_id}", flush=True)
    else:
        print(f"[annotate] Starting pipeline for patient: {patient_id}", flush=True)

    conn = _connect()
    try:
        sessions = _fetch_sessions(conn, patient_id)
        if not sessions:
            print(f"[annotate] No chat sessions found for {patient_id}", flush=True)
            return

        print(f"[annotate] Found {len(sessions)} session(s)", flush=True)

        all_messages = _fetch_all_messages(conn, [s["session_id"] for s in sessions])

        pm              = PatientMemory(conn=conn)
        prev_info       = None   # carries previous iteration's data for delta
        failed_sessions = []     # sessions that errored; reported at the end

        for i, session in enumerate(sessions, 1):
            sid = session["session_id"]

            # The previous iteration may have spent minutes inside the LLM
            # pipeline — make sure the connection is alive before any query.
            conn.ping(reconnect=True)

            # Single-session mode: skip all sessions except the target,
            # but still populate prev_info so the delta chain is correct.
            if target_session_id and sid != target_session_id:
                signal_id = _make_signal_id(patient_id, sid)
                prev_info = {
                    "session_id":   sid,
                    "signal_id":    signal_id,
                    "session_date": session.get("session_date"),
                    "row":          _load_existing_row(conn, signal_id),
                }
                continue

            session_date = session.get("session_date")
            start_time   = session.get("start_time")

            messages = all_messages.get(sid, [])
            if not messages:
                print(f"[annotate] Session {sid}: no messages, skipping", flush=True)
                continue

            signal_id = _make_signal_id(patient_id, sid)

            # ── Skip if already annotated ─────────────────────────────
            if _already_annotated(conn, signal_id):
                print(f"[annotate] Session {i}/{len(sessions)} (id={sid}): already annotated, skipping.", flush=True)
                prev_info = {
                    "session_id":   sid,
                    "signal_id":    signal_id,
                    "session_date": session_date,
                    "row":          _load_existing_row(conn, signal_id),
                }
                continue

            chat_text = _format_chat(messages)
            print(
                f"[annotate] Session {i}/{len(sessions)} "
                f"(id={sid}, msgs={len(messages)})",
                flush=True,
            )

            curr_info = None
            try:
                result = run_session(
                    chat=chat_text,
                    patient_id=patient_id,
                    conversation_id=str(sid),
                    patient_memory=pm,
                )

                row    = result.get("dataset_row", {})
                long_o = result.get("longitudinal_output", {})
                delta  = long_o.get("delta")   # SessionDelta dict or None (session 1)

                curr_info = {
                    "session_id":   sid,
                    "signal_id":    signal_id,
                    "session_date": session_date,
                    "row":          row,
                }

                # The LLM call above can take minutes — re-ping BEFORE opening
                # the transaction (a reconnect mid-transaction would lose it).
                conn.ping(reconnect=True)

                # ── All writes for this session commit atomically ────
                conn.begin()

                _save_pipeline_run(conn, get_manager().run_store.to_dict())
                _save_signal(conn, signal_id, row)
                _save_session_history(
                    conn, sid, patient_id, session_date, start_time,
                    row.get("reasoning_summary", ""),
                    signal_id,
                )

                # Delta only exists from session 2 onwards.
                # Guard against FK failure: from_session_id must exist in session_history.
                if prev_info is not None and delta is not None:
                    if _session_in_history(conn, prev_info["session_id"]):
                        _save_delta(conn, patient_id, prev_info, curr_info, delta)
                    else:
                        print(f"[annotate] Skipping delta for {sid}: previous session {prev_info['session_id']} not in session_history.", flush=True)

                conn.commit()
                prev_info = curr_info
                print(f"[annotate] Session {sid} saved.", flush=True)

            except Exception:
                # Roll back this session's partial writes and keep going.
                try:
                    conn.rollback()
                except Exception:
                    pass
                traceback.print_exc()
                failed_sessions.append(sid)
                print(f"[annotate] Session {sid} FAILED — rolled back, continuing with next session.", flush=True)

                # Keep the delta chain consistent with the pipeline's memory:
                #  - run_session failed (curr_info is None): memory never saw
                #    this session, so the next delta correctly compares
                #    against the previous one — leave prev_info unchanged.
                #  - run_session succeeded but the DB write failed: memory
                #    DID see this session, so advance prev_info; the FK guard
                #    will skip writing the next delta since this session is
                #    not in session_history (rolled back).
                if curr_info is not None:
                    prev_info = curr_info

        if failed_sessions:
            print(
                f"[annotate] Done with errors — {len(failed_sessions)} of "
                f"{len(sessions)} session(s) failed: {failed_sessions}",
                flush=True,
            )
            sys.exit(1)

        print(f"[annotate] Done — all sessions processed for {patient_id}.", flush=True)

    except Exception:
        traceback.print_exc()
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()