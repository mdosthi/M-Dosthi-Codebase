-- Keep the patient distress bit aligned with the latest assessment using > 4.
UPDATE med AS patient
LEFT JOIN (
    SELECT assessment.pat_id, assessment.distress_score
    FROM distress_thermometer AS assessment
    JOIN (
        SELECT pat_id, MAX(id) AS latest_id
        FROM distress_thermometer
        GROUP BY pat_id
    ) AS latest ON latest.latest_id = assessment.id
) AS latest_assessment ON latest_assessment.pat_id = patient.pat_id
SET patient.distress_bit = IF(COALESCE(latest_assessment.distress_score, 0) > 4, 1, 0);