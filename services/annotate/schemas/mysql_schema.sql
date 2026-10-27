-- =============================================================================
-- annotate — longitudinal pipeline MySQL schema
-- MySQL 8.0+ (uses JSON columns, generated columns, CHECK constraints)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- patient_profiles
-- Mutable longitudinal state — one row per patient.
-- -----------------------------------------------------------------------------

CREATE TABLE patient_profiles (
    patient_id          VARCHAR(64)     NOT NULL,
    created_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_updated        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    -- Derived trajectory (ordered list of stage strings)
    stage_trajectory            JSON            NOT NULL DEFAULT (JSON_ARRAY()),
    stage_direction_history     JSON            NOT NULL DEFAULT (JSON_ARRAY()),

    -- Cumulative signal sets
    all_triggers_ever           JSON            NOT NULL DEFAULT (JSON_ARRAY()),
    all_concerns_ever           JSON            NOT NULL DEFAULT (JSON_ARRAY()),
    interventions_tried         JSON            NOT NULL DEFAULT (JSON_ARRAY()),

    -- Persistence sets (last 2+ sessions)
    persistent_triggers         JSON            NOT NULL DEFAULT (JSON_ARRAY()),
    persistent_concerns         JSON            NOT NULL DEFAULT (JSON_ARRAY()),
    resolved_triggers           JSON            NOT NULL DEFAULT (JSON_ARRAY()),

    -- Clinical state
    total_sessions              SMALLINT UNSIGNED   NOT NULL DEFAULT 0,
    stagnation_count            SMALLINT UNSIGNED   NOT NULL DEFAULT 0,
    relapse_count               SMALLINT UNSIGNED   NOT NULL DEFAULT 0,
    best_stage_reached          VARCHAR(32)         NOT NULL DEFAULT 'unknown',
    context_summary             TEXT,

    PRIMARY KEY (patient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- -----------------------------------------------------------------------------
-- session_records
-- Immutable annotation snapshot — one row per session.
-- Never updated after insert.
-- -----------------------------------------------------------------------------

CREATE TABLE session_records (
    session_id              BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    patient_id              VARCHAR(64)         NOT NULL,
    session_number          SMALLINT UNSIGNED   NOT NULL,
    session_date            DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    conversation_id         VARCHAR(128),

    -- Core annotation
    stage_of_change         VARCHAR(32)         NOT NULL DEFAULT 'unknown',
    all_concerns            JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    all_triggers            JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    quit_attempt_history    VARCHAR(64)         NOT NULL DEFAULT 'unknown',
    recommended_intervention JSON               NOT NULL DEFAULT (JSON_ARRAY()),
    reasoning_summary       TEXT,
    confidence_score        FLOAT               CHECK (confidence_score BETWEEN 0.0 AND 1.0),

    -- Pipeline metadata
    debate_rounds_used      TINYINT UNSIGNED,
    vote_agreement          FLOAT               CHECK (vote_agreement BETWEEN 0.0 AND 1.0),
    sanity_passed           TINYINT(1),
    inconsistencies         JSON                NOT NULL DEFAULT (JSON_ARRAY()),

    -- Raw conversation excerpt (first ~500 chars, for context injection)
    conversation_excerpt    VARCHAR(600),

    PRIMARY KEY (id),
    UNIQUE KEY uq_patient_session (patient_id, session_number),
    CONSTRAINT fk_sr_patient
        FOREIGN KEY (patient_id) REFERENCES patient_profiles (patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- -----------------------------------------------------------------------------
-- session_deltas
-- Diff between session N-1 and session N — one row per transition.
-- -----------------------------------------------------------------------------

CREATE TABLE session_deltas (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    patient_id              VARCHAR(64)         NOT NULL,
    from_session            SMALLINT UNSIGNED   NOT NULL,
    to_session              SMALLINT UNSIGNED   NOT NULL,
    from_date               DATETIME,
    to_date                 DATETIME,

    -- Stage change
    stage_before            VARCHAR(32)         NOT NULL DEFAULT 'unknown',
    stage_after             VARCHAR(32)         NOT NULL DEFAULT 'unknown',
    stage_changed           TINYINT(1)          NOT NULL DEFAULT 0,
    stage_direction         VARCHAR(16)         NOT NULL DEFAULT 'unknown',
                                -- progress | regression | relapse | recovery | stable | unknown

    -- Trigger diff
    new_triggers            JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    resolved_triggers       JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    persistent_triggers     JSON                NOT NULL DEFAULT (JSON_ARRAY()),

    -- Concern diff
    new_concerns            JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    resolved_concerns       JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    persistent_concerns     JSON                NOT NULL DEFAULT (JSON_ARRAY()),

    -- Intervention diff
    new_interventions       JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    continuing_interventions JSON               NOT NULL DEFAULT (JSON_ARRAY()),
    dropped_interventions   JSON                NOT NULL DEFAULT (JSON_ARRAY()),

    -- Clinical flags
    relapse_detected        TINYINT(1)          NOT NULL DEFAULT 0,
    rapid_progress_detected TINYINT(1)          NOT NULL DEFAULT 0,
    stagnation_detected     TINYINT(1)          NOT NULL DEFAULT 0,
    concern_shift_detected  TINYINT(1)          NOT NULL DEFAULT 0,
    trigger_resolved        TINYINT(1)          NOT NULL DEFAULT 0,

    -- Quit attempt accumulation
    new_quit_attempts       JSON,
    cumulative_quit_history TEXT,

    -- LLM narrative
    clinical_summary        TEXT,

    PRIMARY KEY (id),
    UNIQUE KEY uq_delta_transition (patient_id, from_session, to_session),
    CONSTRAINT fk_sd_patient
        FOREIGN KEY (patient_id) REFERENCES patient_profiles (patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- -----------------------------------------------------------------------------
-- longitudinal_annotations
-- Final combined output per pipeline run (current annotation + longitudinal context).
-- -----------------------------------------------------------------------------

CREATE TABLE longitudinal_annotations (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    patient_id              VARCHAR(64)         NOT NULL,
    session_number          SMALLINT UNSIGNED   NOT NULL,

    -- Full current-session annotation blob (mirrors DatasetRow)
    current_annotation      JSON                NOT NULL DEFAULT (JSON_OBJECT()),

    -- FK to the delta for this session transition (NULL for session 1)
    session_delta_id        BIGINT UNSIGNED,

    -- Longitudinal context snapshots at time of run
    stage_trajectory        JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    persistent_triggers     JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    persistent_concerns     JSON                NOT NULL DEFAULT (JSON_ARRAY()),
    interventions_tried     JSON                NOT NULL DEFAULT (JSON_ARRAY()),

    -- Longitudinal flags
    relapse_detected        TINYINT(1)          NOT NULL DEFAULT 0,
    stagnation_detected     TINYINT(1)          NOT NULL DEFAULT 0,
    overall_progress        VARCHAR(16)         NOT NULL DEFAULT 'unknown',
                                -- improving | stable | regression | relapse | unknown
    longitudinal_flags      JSON                NOT NULL DEFAULT (JSON_ARRAY()),

    created_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id),
    UNIQUE KEY uq_la_patient_session (patient_id, session_number),
    CONSTRAINT fk_la_patient
        FOREIGN KEY (patient_id) REFERENCES patient_profiles (patient_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_la_delta
        FOREIGN KEY (session_delta_id) REFERENCES session_deltas (id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- -----------------------------------------------------------------------------
-- pipeline_runs
-- Full trace of every agent call in a pipeline run — one row per run.
-- rounds  : JSON array of {round_number, extraction, confidence, revision}
-- All post-loop results stored as JSON blobs for flexibility.
-- -----------------------------------------------------------------------------

CREATE TABLE pipeline_runs (
    run_id              VARCHAR(64)         NOT NULL,
    conversation_id     VARCHAR(128),
    patient_id          VARCHAR(64),
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    total_rounds        TINYINT UNSIGNED    NOT NULL DEFAULT 1,

    -- Extraction / confidence / revision trace (one entry per round)
    rounds              JSON                NOT NULL DEFAULT (JSON_ARRAY()),

    -- Post-loop results
    consensus           JSON,
    dataset_row         JSON,

    -- Longitudinal (NULL for session 1)
    session_delta       JSON,
    longitudinal_sanity JSON,
    longitudinal_output JSON,

    PRIMARY KEY (run_id),
    INDEX idx_pr_conversation (conversation_id),
    INDEX idx_pr_patient      (patient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- -----------------------------------------------------------------------------
-- Indexes for common access patterns
-- -----------------------------------------------------------------------------

-- Look up all sessions for a patient in order
CREATE INDEX idx_sr_patient_session ON session_records (patient_id, session_number);

-- Filter deltas by clinical flags
CREATE INDEX idx_sd_relapse    ON session_deltas (patient_id, relapse_detected);
CREATE INDEX idx_sd_stagnation ON session_deltas (patient_id, stagnation_detected);
CREATE INDEX idx_sd_direction  ON session_deltas (patient_id, stage_direction);

-- Filter annotations by overall progress
CREATE INDEX idx_la_progress ON longitudinal_annotations (patient_id, overall_progress);
