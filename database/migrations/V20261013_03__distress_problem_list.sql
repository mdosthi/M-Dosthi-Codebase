-- Store each selected Distress Thermometer concern separately from the rating.
CREATE TABLE IF NOT EXISTS distress_thermometer_problem (
    id BIGINT NOT NULL AUTO_INCREMENT,
    screening_id BIGINT NOT NULL,
    category VARCHAR(64) NOT NULL,
    concern VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_distress_screening_concern (screening_id, category, concern),
    KEY idx_distress_problem_screening (screening_id),
    CONSTRAINT fk_distress_problem_screening FOREIGN KEY (screening_id)
        REFERENCES distress_thermometer (id) ON DELETE CASCADE
) ENGINE=InnoDB;
