-- Distress Thermometer screening history and latest-score patient flag.
ALTER TABLE med
    ADD COLUMN distress_bit TINYINT(1) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS distress_thermometer (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(18) NOT NULL,
    distress_score TINYINT UNSIGNED NOT NULL,
    screening_date DATE NOT NULL,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_distress_patient_date (pat_id, screening_date, id),
    CONSTRAINT fk_distress_patient FOREIGN KEY (pat_id) REFERENCES med (pat_id),
    CONSTRAINT chk_distress_score CHECK (distress_score <= 10)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
