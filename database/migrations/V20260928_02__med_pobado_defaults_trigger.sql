-- The legacy DataEntryFrm.InsertMed()/InsertMedWithoutDocAssign() RMI methods build an INSERT
-- covering every column returned by `med`'s metadata, passing an explicit SQL NULL for any
-- column not present in the submitted registration form (e.g. the new pobado/psy columns).
-- With STRICT_TRANS_TABLES enabled, an explicit NULL into a NOT NULL column fails the whole
-- registration ("ERROR / Try Again"). This trigger substitutes the intended defaults so
-- registration keeps working without touching the compiled legacy RMI server.
DROP TRIGGER IF EXISTS trg_med_pobado_defaults;

DELIMITER $$
CREATE TRIGGER trg_med_pobado_defaults BEFORE INSERT ON med
FOR EACH ROW
BEGIN
    IF NEW.pobado_flag IS NULL THEN SET NEW.pobado_flag = 'N'; END IF;
    IF NEW.rct_ready IS NULL THEN SET NEW.rct_ready = 'N'; END IF;
    IF NEW.psy_referred IS NULL THEN SET NEW.psy_referred = 'N'; END IF;
END$$
DELIMITER ;
