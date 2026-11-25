-- =============================================================================
-- Migration: add pipeline_runs to M-Dosthi_merged
-- Run once against the M-Dosthi_merged database.
-- MySQL 8.0+ required (JSON columns).
-- =============================================================================

CREATE TABLE IF NOT EXISTS pipeline_runs (
    run_id              VARCHAR(64)         NOT NULL,
    conversation_id     VARCHAR(128),
    patient_id          VARCHAR(64),
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    total_rounds        TINYINT UNSIGNED    NOT NULL DEFAULT 1,

    -- Per-round trace: [{round_number, extraction, confidence, revision}, ...]
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
