-- =============================================================================
-- Complete Spring Boot API & Longitudinal Schema Migration for M-Dosthi
-- Reconciles tables and columns added after the 2025-01-25 base SQL snapshot.
-- Safe to run multiple times (idempotent on MySQL 8.0 / 9.x / 26.x).
-- =============================================================================

DELIMITER $$
DROP PROCEDURE IF EXISTS add_col_if_missing$$
CREATE PROCEDURE add_col_if_missing(
    IN tbl VARCHAR(64),
    IN col VARCHAR(64),
    IN col_def VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE()
          AND table_name = tbl
          AND column_name = col
    ) THEN
        SET @ddl = CONCAT('ALTER TABLE `', tbl, '` ADD COLUMN `', col, '` ', col_def);
        PREPARE stmt FROM @ddl;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$
DELIMITER ;

-- 1. Add missing columns on `login` and remove duplicate plain-text 'admin' row
CALL add_col_if_missing('login', 'rctFlag', 'INT DEFAULT 0');
CALL add_col_if_missing('login', 'dpdp_agreed', 'INT DEFAULT 0');
CALL add_col_if_missing('login', 'wa_sent', 'INT DEFAULT 0');

DELETE FROM `login` WHERE `uid` = 'admin' AND `rg_no` = '' AND `pwd` = 'admin';

-- 2. Add missing columns on `med` and `record_log`
CALL add_col_if_missing('med', 'clinical_history', 'VARCHAR(10) DEFAULT NULL');
CALL add_col_if_missing('med', 'family_history', 'VARCHAR(10) DEFAULT NULL');
CALL add_col_if_missing('med', 'bidi_count', 'SMALLINT DEFAULT NULL');
CALL add_col_if_missing('med', 'substance_duration', 'SMALLINT DEFAULT NULL');
CALL add_col_if_missing('med', 'substance_duration_unit', 'VARCHAR(10) DEFAULT NULL');
CALL add_col_if_missing('record_log', 'score', 'INT DEFAULT NULL COMMENT ''Calculated score for the survey response''');

DROP PROCEDURE IF EXISTS add_col_if_missing;

-- 3. Signal & Session History tables (used by SuicideIdeationTracker & OllamaService)
CREATE TABLE IF NOT EXISTS `signal_history` (
  `signal_id` VARCHAR(255) NOT NULL,
  `concerns` TEXT,
  `triggers` TEXT,
  `readiness` VARCHAR(100) DEFAULT NULL,
  `advice` TEXT,
  `quit_history` TEXT,
  `suicidal_ideation` TINYINT(1) NOT NULL DEFAULT 0,
  `is_processed` INT DEFAULT 0,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`signal_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `session_history` (
  `session_id` VARCHAR(255) NOT NULL,
  `pat_id` VARCHAR(18) NOT NULL,
  `session_date` DATE DEFAULT NULL,
  `start_time` DATETIME NOT NULL,
  `session_summary` TEXT,
  `signal_id` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`session_id`),
  KEY `idx_pat_id` (`pat_id`),
  KEY `idx_signal_id` (`signal_id`),
  CONSTRAINT `fk_session_signal` FOREIGN KEY (`signal_id`) REFERENCES `signal_history` (`signal_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `session_deltas` (
  `delta_id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `pat_id` VARCHAR(18) NOT NULL,
  `from_session_id` VARCHAR(255) NOT NULL,
  `to_session_id` VARCHAR(255) NOT NULL,
  `from_signal_id` VARCHAR(255) DEFAULT NULL,
  `to_signal_id` VARCHAR(255) DEFAULT NULL,
  `from_session_date` DATE DEFAULT NULL,
  `to_session_date` DATE DEFAULT NULL,
  `readiness_before` VARCHAR(100) DEFAULT NULL,
  `readiness_after` VARCHAR(100) DEFAULT NULL,
  `readiness_changed` TINYINT(1) NOT NULL DEFAULT 0,
  `concerns_before` TEXT,
  `concerns_after` TEXT,
  `new_concerns` TEXT,
  `resolved_concerns` TEXT,
  `persistent_concerns` TEXT,
  `concern_changed` TINYINT(1) NOT NULL DEFAULT 0,
  `triggers_before` TEXT,
  `triggers_after` TEXT,
  `new_triggers` TEXT,
  `resolved_triggers` TEXT,
  `persistent_triggers` TEXT,
  `trigger_changed` TINYINT(1) NOT NULL DEFAULT 0,
  `advice_before` TEXT,
  `advice_after` TEXT,
  `new_advice` TEXT,
  `continued_advice` TEXT,
  `dropped_advice` TEXT,
  `advice_changed` TINYINT(1) NOT NULL DEFAULT 0,
  `quit_history_before` TEXT,
  `quit_history_after` TEXT,
  `quit_history_changed` TINYINT(1) NOT NULL DEFAULT 0,
  `new_quit_attempts` JSON DEFAULT NULL,
  `cumulative_quit_history` TEXT,
  `relapse_detected` TINYINT(1) NOT NULL DEFAULT 0,
  `progress_detected` TINYINT(1) NOT NULL DEFAULT 0,
  `rapid_progress_detected` TINYINT(1) NOT NULL DEFAULT 0,
  `stagnation_detected` TINYINT(1) NOT NULL DEFAULT 0,
  `concern_shift_detected` TINYINT(1) NOT NULL DEFAULT 0,
  `trigger_resolved` TINYINT(1) NOT NULL DEFAULT 0,
  `clinical_summary` TEXT,
  `created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`delta_id`),
  UNIQUE KEY `uq_session_transition` (`from_session_id`, `to_session_id`),
  KEY `idx_pat_id` (`pat_id`),
  KEY `idx_from_session` (`from_session_id`),
  KEY `idx_to_session` (`to_session_id`),
  KEY `idx_from_signal` (`from_signal_id`),
  KEY `idx_to_signal` (`to_signal_id`),
  CONSTRAINT `fk_sd_from_session` FOREIGN KEY (`from_session_id`) REFERENCES `session_history` (`session_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_sd_to_session` FOREIGN KEY (`to_session_id`) REFERENCES `session_history` (`session_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_sd_from_signal` FOREIGN KEY (`from_signal_id`) REFERENCES `signal_history` (`signal_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_sd_to_signal` FOREIGN KEY (`to_signal_id`) REFERENCES `signal_history` (`signal_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Chat & App telemetry tables
CREATE TABLE IF NOT EXISTS `chat_control` (
  `pat_id` VARCHAR(18) NOT NULL,
  `daily_chat_limit` INT DEFAULT 3,
  `max_session_duration` INT DEFAULT 1800,
  `min_session_interval` INT DEFAULT 3600,
  `blackout_start_time` TIME DEFAULT NULL,
  `blackout_end_time` TIME DEFAULT NULL,
  `blackout_days` TEXT,
  `chat_type` VARCHAR(20) DEFAULT 'original',
  PRIMARY KEY (`pat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chat_sessions` (
  `session_id` VARCHAR(255) NOT NULL,
  `pat_id` VARCHAR(18) NOT NULL,
  `session_date` DATE DEFAULT NULL,
  `start_time` DATETIME NOT NULL,
  `end_time` DATETIME DEFAULT NULL,
  `duration` INT DEFAULT NULL,
  `session_notes` TEXT,
  `session_status` TEXT,
  `language_preference` VARCHAR(5) NOT NULL DEFAULT 'en' COMMENT 'Session language: en or bn. Locked in at session creation.',
  PRIMARY KEY (`session_id`),
  KEY `pat_id` (`pat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `chat_messages` (
  `message_id` VARCHAR(255) NOT NULL,
  `session_id` VARCHAR(255) NOT NULL,
  `message_sequence` INT NOT NULL,
  `sender_type` VARCHAR(50) NOT NULL,
  `message_content` TEXT NOT NULL,
  `timestamp` DATETIME NOT NULL,
  `is_read` TINYINT(1) DEFAULT 0,
  `response_time` INT DEFAULT NULL,
  `file_format` VARCHAR(20) DEFAULT 'json',
  `file_size` INT DEFAULT NULL,
  PRIMARY KEY (`message_id`),
  KEY `session_id` (`session_id`),
  CONSTRAINT `chat_messages_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `chat_sessions` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `audio_recordings` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `pat_id` VARCHAR(18) NOT NULL,
  `file_path` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `recorded_date` DATE DEFAULT NULL,
  `upload_date` DATETIME NOT NULL,
  `uploaded_by` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `pat_id` (`pat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `psyNotes` (
  `pat_id` CHAR(18) NOT NULL,
  `notes` LONGTEXT,
  `report_link` VARCHAR(60) DEFAULT NULL,
  `testdate` DATETIME DEFAULT NULL,
  `entrydate` DATETIME NOT NULL,
  `serno` INT NOT NULL,
  PRIMARY KEY (`pat_id`, `entrydate`, `serno`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `terminal_logs` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `session_id` VARCHAR(255) NOT NULL,
  `command` TEXT NOT NULL,
  `output` TEXT,
  `timestamp` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_session_timestamp` (`session_id`, `timestamp`),
  KEY `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_progress` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `userid` VARCHAR(200) NOT NULL,
  `item_id` VARCHAR(255) NOT NULL,
  `item_type` VARCHAR(50) NOT NULL,
  `open_count` INT UNSIGNED NOT NULL DEFAULT 1,
  `last_accessed` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_item` (`userid`, `item_id`, `item_type`),
  KEY `idx_userid` (`userid`),
  KEY `idx_item` (`item_id`),
  KEY `idx_item_type` (`item_type`),
  KEY `idx_last_accessed` (`last_accessed`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_time_app` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `userid` VARCHAR(200) NOT NULL,
  `timespent` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Seconds spent in app',
  `date` DATE NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_date` (`userid`, `date`),
  KEY `idx_userid` (`userid`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
