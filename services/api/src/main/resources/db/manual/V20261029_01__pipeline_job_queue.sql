CREATE TABLE IF NOT EXISTS pipeline_jobs (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(64) NOT NULL,
    session_id VARCHAR(128) NULL,
    force_reannotate TINYINT(1) NOT NULL DEFAULT 0,
    status VARCHAR(16) NOT NULL DEFAULT 'pending',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME NULL,
    finished_at DATETIME NULL,
    error_message TEXT NULL,
    PRIMARY KEY (id),
    KEY idx_pipeline_jobs_status_id (status, id),
    KEY idx_pipeline_jobs_status_finished_at (status, finished_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pipeline_settings (
    id TINYINT UNSIGNED NOT NULL,
    start_time TIME NOT NULL DEFAULT '00:00:00',
    end_time TIME NOT NULL DEFAULT '02:00:00',
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO pipeline_settings (id, start_time, end_time)
VALUES (1, '00:00:00', '02:00:00');
