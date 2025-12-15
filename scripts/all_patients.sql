WITH all_patients_with_notes AS (
    SELECT DISTINCT subject_id
    FROM mimic_omop.notes_norm
    WHERE text IS NOT NULL AND LENGTH(text) > 50
),

icd_positive AS (
    SELECT DISTINCT subject_id
    FROM mimic_omop.insomnia_cohort
)

SELECT subject_id,
       CASE WHEN subject_id IN (SELECT subject_id FROM icd_positive)
            THEN 1 ELSE 0 END AS icd_insomnia
FROM all_patients_with_notes;