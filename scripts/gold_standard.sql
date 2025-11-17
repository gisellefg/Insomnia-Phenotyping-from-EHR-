DROP TABLE IF EXISTS mimic_omop.insomnia_patients_final;

CREATE TABLE mimic_omop.insomnia_patients_final AS
WITH all_rules AS (
    SELECT subject_id, 'A' AS rule FROM mimic_omop.rulea_patients
    UNION ALL
    SELECT subject_id, 'B' FROM mimic_omop.insomnia_drug_patients
    UNION ALL
    SELECT subject_id, 'C' FROM mimic_omop.insomnia_drug_patients
),
agg AS (
    SELECT subject_id,
           BOOL_OR(rule='A') AS rule_a,
           BOOL_OR(rule='B') AS rule_b,
           BOOL_OR(rule='C') AS rule_c
    FROM all_rules
    GROUP BY subject_id
)
SELECT *, (rule_a OR rule_b OR rule_c) AS any_rule
FROM agg;



CREATE TABLE mimic_omop.insomnia_cohort AS
SELECT * FROM mimic_omop.insomnia_patients_final;



DROP TABLE IF EXISTS kb.insomnia_status;

CREATE TABLE kb.insomnia_status AS
SELECT * FROM mimic_omop.insomnia_patients_final;
