-- PO Bado workflow flags on the patient (med) record.
-- pobado_flag: 'N' until a PO Bado screening has been recorded for the patient, then 'Y'.
-- rct_ready: set to 'Y' when the most recent PO Bado total_score is between 0 and 9 (inclusive).
-- psy_referred / psy_referred_date: set when the admin refers the patient to a psychologist
-- instead of performing PO Bado screening directly after registration.
ALTER TABLE med
    ADD COLUMN pobado_flag CHAR(1) NOT NULL DEFAULT 'N',
    ADD COLUMN rct_ready CHAR(1) NOT NULL DEFAULT 'N',
    ADD COLUMN psy_referred CHAR(1) NOT NULL DEFAULT 'N',
    ADD COLUMN psy_referred_date DATETIME NULL;

UPDATE med AS m
JOIN (
    SELECT screening.cr_number, screening.total_score
    FROM pobado_screening AS screening
    JOIN (
        SELECT cr_number, MAX(id) AS latest_id
        FROM pobado_screening
        GROUP BY cr_number
    ) AS latest ON latest.latest_id = screening.id
) AS latest ON UPPER(latest.cr_number) = UPPER(m.pat_id)
SET m.pobado_flag = 'Y',
    m.rct_ready = IF(latest.total_score BETWEEN 0 AND 9, 'Y', 'N');
