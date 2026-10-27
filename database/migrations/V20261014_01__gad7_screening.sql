-- GAD-7 screening item responses, total, and derived anxiety category.
CREATE TABLE IF NOT EXISTS gad7_screening (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(18) NOT NULL,
    patient_name VARCHAR(200) NULL,
    screening_date DATE NOT NULL,
    q1 TINYINT UNSIGNED NOT NULL,
    q2 TINYINT UNSIGNED NOT NULL,
    q3 TINYINT UNSIGNED NOT NULL,
    q4 TINYINT UNSIGNED NOT NULL,
    q5 TINYINT UNSIGNED NOT NULL,
    q6 TINYINT UNSIGNED NOT NULL,
    q7 TINYINT UNSIGNED NOT NULL,
    total_score TINYINT UNSIGNED NOT NULL,
    anxiety_category VARCHAR(32) NOT NULL,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_gad7_patient_date (pat_id, screening_date, id),
    CONSTRAINT fk_gad7_patient FOREIGN KEY (pat_id) REFERENCES med (pat_id),
    CONSTRAINT chk_gad7_scores CHECK (
        q1 <= 3 AND q2 <= 3 AND q3 <= 3 AND q4 <= 3 AND q5 <= 3 AND q6 <= 3 AND q7 <= 3 AND total_score <= 21
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;
