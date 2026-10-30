
-- Minimal schema for local legacy account, patient registration, and screening tests only.
-- This is not the full iMediX/M-Dosthi application schema.

CREATE TABLE login (
    uid VARCHAR(64) NOT NULL,
    pwd CHAR(32) NOT NULL,
    name VARCHAR(128) NOT NULL,
    crtdate DATETIME NOT NULL,
    type VARCHAR(16) NOT NULL,
    phone VARCHAR(32) NULL,
    address VARCHAR(255) NULL,
    emailid VARCHAR(255) NULL,
    qualification VARCHAR(128) NULL,
    designation VARCHAR(128) NULL,
    dis VARCHAR(64) NULL,
    rg_no VARCHAR(64) NOT NULL,
    center VARCHAR(16) NOT NULL,
    active CHAR(1) NOT NULL,
    available CHAR(1) NOT NULL DEFAULT 'N',
    referral CHAR(1) NOT NULL DEFAULT 'N',
    consent CHAR(1) NULL,
    dpdp_agreed TINYINT NOT NULL DEFAULT 0,
    rctFlag INT NOT NULL DEFAULT 0,
    verified CHAR(1) NOT NULL,
    verifemail CHAR(1) NOT NULL DEFAULT 'N',
    verifphone CHAR(1) NOT NULL DEFAULT 'N',
    PRIMARY KEY (uid),
    UNIQUE KEY uq_login_rg_no (rg_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE med (
    pat_id VARCHAR(32) NOT NULL,
    entrydate DATETIME NULL,
    serno INT NOT NULL DEFAULT 0,
    distress_bit INT NOT NULL DEFAULT 0,
    pre VARCHAR(16) NULL,
    pat_name VARCHAR(45) NULL,
    m_name VARCHAR(45) NULL,
    l_name VARCHAR(45) NULL,
    religion VARCHAR(16) NULL,
    m_status VARCHAR(16) NULL,
    clinical_history VARCHAR(16) NULL,
    family_history VARCHAR(16) NULL,
    caste_category VARCHAR(16) NULL,
    sex VARCHAR(8) NULL,
    referring_doctor VARCHAR(64) NULL,
    opdno VARCHAR(24) NULL,
    dateofbirth DATE NULL,
    ageyy VARCHAR(8) NULL,
    agemm VARCHAR(8) NULL,
    agedd VARCHAR(8) NULL,
    age VARCHAR(16) NULL,
    type VARCHAR(8) NULL,
    bidi_count VARCHAR(16) NULL,
    substance_duration INT NULL,
    substance_duration_unit VARCHAR(16) NULL,
    class VARCHAR(64) NULL,
    persidtype VARCHAR(32) NULL,
    persidvalue VARCHAR(64) NULL,
    persidchecked VARCHAR(8) NULL,
    emailid VARCHAR(255) NULL,
    emailVerified CHAR(1) NULL,
    relationship VARCHAR(32) NULL,
    primarypatid VARCHAR(32) NULL,
    addline1 VARCHAR(200) NULL,
    policestn VARCHAR(100) NULL,
    phone VARCHAR(32) NULL,
    phoneVerified CHAR(1) NULL,
    city VARCHAR(100) NULL,
    dist VARCHAR(8) NULL,
    state VARCHAR(8) NULL,
    country VARCHAR(64) NULL,
    pin VARCHAR(8) NULL,
    pat_person VARCHAR(100) NULL,
    pat_relation VARCHAR(100) NULL,
    pat_person_add VARCHAR(200) NULL,
    consent VARCHAR(8) NULL,
    PRIMARY KEY (pat_id),
    KEY ix_med_personal_identity (persidtype, persidvalue)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE forms (
    name VARCHAR(32) NOT NULL,
    description VARCHAR(128) NULL,
    PRIMARY KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO forms (name, description) VALUES ('MED', 'Patient registration');

CREATE TABLE listofforms (
    pat_id VARCHAR(32) NOT NULL,
    type VARCHAR(32) NOT NULL,
    date DATETIME NULL,
    serno INT NOT NULL DEFAULT 0,
    sent CHAR(1) NULL,
    field6 VARCHAR(64) NULL,
    field7 VARCHAR(64) NULL,
    rg_no VARCHAR(64) NULL,
    field9 VARCHAR(64) NULL,
    KEY ix_listofforms_pat_id (pat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE center (
    code VARCHAR(16) NOT NULL,
    name VARCHAR(128) NOT NULL,
    centertype CHAR(1) NULL,
    expdate VARCHAR(128) NULL,
    visibility CHAR(1) NULL,
    PRIMARY KEY (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE lpatq (
    pat_id VARCHAR(32) NOT NULL,
    entrydate DATETIME NULL,
    appdate DATETIME NULL,
    assigneddoc VARCHAR(64) NULL,
    discategory VARCHAR(64) NULL,
    checked CHAR(1) NULL,
    delflag CHAR(1) NULL,
    opdno VARCHAR(24) NULL,
    KEY ix_lpatq_pat_id (pat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE patientvisit (
    pat_id VARCHAR(32) NOT NULL,
    visitdate DATETIME NULL,
    attending_person VARCHAR(64) NULL,
    KEY ix_patientvisit_pat_id (pat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tpatq (
    assigneddoc VARCHAR(64) NULL,
    teleconsultdt DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tpatwaitq (
    referred_doc VARCHAR(64) NULL,
    status CHAR(1) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pobado_screening (
    id BIGINT NOT NULL AUTO_INCREMENT,
    cr_number VARCHAR(64) NOT NULL,
    assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment',
    phone_number VARCHAR(32) NULL,
    patient_name VARCHAR(200) NOT NULL,
    screening_date DATE NOT NULL,
    age TINYINT UNSIGNED NULL,
    gender VARCHAR(16) NULL,
    relationship VARCHAR(16) NULL,
    children VARCHAR(16) NULL,
    work_situation VARCHAR(100) NULL,
    tumour_diagnosis VARCHAR(3000) NULL,
    metastasis VARCHAR(16) NULL,
    diagnosis_date CHAR(7) NULL,
    disease_state VARCHAR(100) NULL,
    treatments VARCHAR(3000) NULL,
    physical_diseases VARCHAR(3000) NULL,
    psychoactive_medication VARCHAR(3000) NULL,
    psych_treatment VARCHAR(16) NULL,
    performance_status TINYINT UNSIGNED NULL,
    fatigue TINYINT UNSIGNED NOT NULL DEFAULT 0,
    mood TINYINT UNSIGNED NOT NULL DEFAULT 0,
    anxiety TINYINT UNSIGNED NOT NULL DEFAULT 0,
    depression TINYINT UNSIGNED NOT NULL DEFAULT 0,
    limitations TINYINT UNSIGNED NOT NULL DEFAULT 0,
    social_problems TINYINT UNSIGNED NOT NULL DEFAULT 0,
    total_score TINYINT UNSIGNED NOT NULL DEFAULT 0,
    substance_use VARCHAR(100) NULL,
    last_substance_used VARCHAR(100) NULL,
    follow_up_date DATE NULL,
    bed_number VARCHAR(50) NULL,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_pobado_patient_checkpoint (cr_number, assessment_checkpoint)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE distress_thermometer (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(32) NOT NULL,
    assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment',
    distress_score TINYINT UNSIGNED NOT NULL,
    screening_date DATE NOT NULL,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_distress_patient_checkpoint (pat_id, assessment_checkpoint)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE distress_thermometer_problem (
    id BIGINT NOT NULL AUTO_INCREMENT,
    screening_id BIGINT NOT NULL,
    category VARCHAR(64) NOT NULL,
    concern VARCHAR(100) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_distress_screening_concern (screening_id, category, concern),
    KEY idx_distress_problem_screening (screening_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE phq9_screening (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(32) NOT NULL,
    assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment',
    patient_name VARCHAR(200) NULL,
    screening_date DATE NOT NULL,
    q1 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q2 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q3 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q4 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q5 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q6 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q7 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q8 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    q9 TINYINT UNSIGNED NOT NULL DEFAULT 0,
    total_score TINYINT UNSIGNED NOT NULL DEFAULT 0,
    recorded_by VARCHAR(64) NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_phq9_patient_checkpoint (pat_id, assessment_checkpoint)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE gad7_screening (
    id BIGINT NOT NULL AUTO_INCREMENT,
    pat_id VARCHAR(32) NOT NULL,
    assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment',
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
    KEY idx_gad7_patient_checkpoint (pat_id, assessment_checkpoint)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE chat_control (
    pat_id VARCHAR(64) NOT NULL,
    daily_chat_limit INT NOT NULL DEFAULT 3,
    max_session_duration INT NOT NULL DEFAULT 1800,
    min_session_interval INT NOT NULL DEFAULT 3600,
    blackout_start_time TIME NULL,
    blackout_end_time TIME NULL,
    blackout_days VARCHAR(128) NULL,
    chat_type VARCHAR(32) NOT NULL DEFAULT 'original',
    PRIMARY KEY (pat_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE chat_sessions (
    session_id VARCHAR(64) NOT NULL,
    pat_id VARCHAR(64) NOT NULL,
    session_date DATE NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NULL,
    duration INT NULL,
    session_notes TEXT NULL,
    session_status VARCHAR(32) NOT NULL,
    language_preference VARCHAR(8) NOT NULL DEFAULT 'en',
    PRIMARY KEY (session_id),
    KEY idx_chat_sessions_patient_start (pat_id, start_time),
    KEY idx_chat_sessions_patient_date (pat_id, session_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE chat_messages (
    message_id VARCHAR(64) NOT NULL,
    session_id VARCHAR(64) NOT NULL,
    message_sequence INT NOT NULL,
    sender_type VARCHAR(32) NOT NULL,
    message_content LONGTEXT NOT NULL,
    `timestamp` DATETIME NOT NULL,
    is_read TINYINT(1) NOT NULL DEFAULT 0,
    response_time INT NULL,
    file_format VARCHAR(32) NULL DEFAULT 'json',
    file_size INT NULL,
    PRIMARY KEY (message_id),
    UNIQUE KEY uq_chat_messages_session_sequence (session_id, message_sequence),
    KEY idx_chat_messages_session_timestamp (session_id, `timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
