-- Doctor/psychologist patient monitoring records: therapy changes, metastasis state and distress follow-up actions.
CREATE TABLE IF NOT EXISTS patient_therapy_change (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(32) NOT NULL,
    previous_therapy VARCHAR(255) NULL,
    new_therapy VARCHAR(255) NOT NULL,
    reason VARCHAR(1000) NULL,
    change_date DATE NOT NULL,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_therapy_patient (pat_id, change_date, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS patient_metastasis_state (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(32) NOT NULL,
    state VARCHAR(2000) NOT NULL,
    notes VARCHAR(1000) NULL,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_metastasis_patient (pat_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS patient_distress_action (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(32) NOT NULL,
    action VARCHAR(100) NOT NULL,
    remarks VARCHAR(1000) NULL,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_distress_action_patient (pat_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
