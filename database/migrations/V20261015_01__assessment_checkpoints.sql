-- Store the assessment checkpoint explicitly so the queue can track baseline and 4/8/12-week rounds.
-- Existing screenings are treated as baseline history; each new screening receives the checkpoint from the queue.
ALTER TABLE pobado_screening
    ADD COLUMN assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment';

ALTER TABLE distress_thermometer
    ADD COLUMN assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment';

ALTER TABLE phq9_screening
    ADD COLUMN assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment';

ALTER TABLE gad7_screening
    ADD COLUMN assessment_checkpoint VARCHAR(32) NOT NULL DEFAULT 'Baseline Assessment';

CREATE INDEX idx_pobado_checkpoint_patient ON pobado_screening (cr_number, assessment_checkpoint);
CREATE INDEX idx_distress_checkpoint_patient ON distress_thermometer (pat_id, assessment_checkpoint);
CREATE INDEX idx_phq9_checkpoint_patient ON phq9_screening (pat_id, assessment_checkpoint);
CREATE INDEX idx_gad7_checkpoint_patient ON gad7_screening (pat_id, assessment_checkpoint);
