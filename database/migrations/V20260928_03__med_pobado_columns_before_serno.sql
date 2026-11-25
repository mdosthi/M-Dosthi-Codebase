-- The legacy DataEntryFrm.InsertMed()/InsertMedWithoutDocAssign() RMI methods iterate
-- `med`'s columns in physical order and close the INSERT VALUES(...) parenthesis right
-- after the `serno` column, assuming it is always last. Plain ADD COLUMN appended the new
-- pobado/psy columns after `serno`, producing malformed SQL ("...0)NULL,NULL,...").
-- Reposition them before `serno` so registration inserts stay syntactically valid.
ALTER TABLE med MODIFY COLUMN pobado_flag CHAR(1) NOT NULL DEFAULT 'N' AFTER category;
ALTER TABLE med MODIFY COLUMN rct_ready CHAR(1) NOT NULL DEFAULT 'N' AFTER pobado_flag;
ALTER TABLE med MODIFY COLUMN psy_referred CHAR(1) NOT NULL DEFAULT 'N' AFTER rct_ready;
ALTER TABLE med MODIFY COLUMN psy_referred_date DATETIME NULL AFTER psy_referred;
