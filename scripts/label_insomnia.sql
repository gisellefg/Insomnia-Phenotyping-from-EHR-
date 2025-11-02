--Rule A--
CREATE TABLE mimic_omop.insomnia_diagnoses AS
SELECT DISTINCT d.subject_id,
       d.hadm_id,
       d.concept_id,
       c.concept_code,
       c.concept_name,
       c.vocabulary_id
FROM mimic_omop.diagnoses_mapped d
JOIN omop.concept c
  ON d.concept_id = c.concept_id
WHERE (
        (c.vocabulary_id = 'ICD10CM' AND c.concept_code IN (
            'F51.01','F51.02','F51.03','F51.04','F51.09',
            'G47.00','G47.01','G47.09'
        ))
     OR
        (c.vocabulary_id = 'ICD9CM' AND c.concept_code = '780.52')
      );


--Rule B--
DROP TABLE IF EXISTS mimic_omop.insomnia_drug_patients;

CREATE TABLE mimic_omop.insomnia_drug_patients AS
SELECT DISTINCT 
    p.subject_id,
    p.hadm_id,
    CASE
        -- Primary insomnia drugs (Rule B)
        WHEN p.drug ILIKE '%ZOLPIDEM%'      THEN 'Zolpidem'
        WHEN p.drug ILIKE '%ESZOPICLONE%'   THEN 'Eszopiclone'
        WHEN p.drug ILIKE '%TEMAZEPAM%'     THEN 'Temazepam'
        WHEN p.drug ILIKE '%TRIAZOLAM%'     THEN 'Triazolam'
        WHEN p.drug ILIKE '%SUVOREXANT%'    THEN 'Suvorexant'
        -- Secondary (Rule C)
        WHEN p.drug ILIKE '%MELATONIN%'     THEN 'Melatonin'
        WHEN p.drug ILIKE '%TRAZODONE%'     THEN 'Trazodone'
        WHEN p.drug ILIKE '%DOXEPIN%'       THEN 'Doxepin'
        WHEN p.drug ILIKE '%MIRTAZAPINE%'   THEN 'Mirtazapine'
        WHEN p.drug ILIKE '%QUETIAPINE%'    THEN 'Quetiapine'
    END AS drug_generic,
    CASE
        WHEN p.drug ILIKE '%ZOLPIDEM%' 
          OR p.drug ILIKE '%ESZOPICLONE%' 
          OR p.drug ILIKE '%TEMAZEPAM%' 
          OR p.drug ILIKE '%TRIAZOLAM%' 
          OR p.drug ILIKE '%SUVOREXANT%' THEN 'primary'
        WHEN p.drug ILIKE '%MELATONIN%' 
          OR p.drug ILIKE '%TRAZODONE%' 
          OR p.drug ILIKE '%DOXEPIN%' 
          OR p.drug ILIKE '%MIRTAZAPINE%' 
          OR p.drug ILIKE '%QUETIAPINE%' THEN 'secondary'
    END AS category
FROM mimic_omop.prescriptions p
WHERE p.drug ILIKE ANY (ARRAY[
    '%ZOLPIDEM%', '%ESZOPICLONE%', '%TEMAZEPAM%', '%TRIAZOLAM%', '%SUVOREXANT%',
    '%MELATONIN%', '%TRAZODONE%', '%DOXEPIN%', '%MIRTAZAPINE%', '%QUETIAPINE%'
]);

-- Create temporary concept lists for each group
DROP TABLE IF EXISTS mimic_omop.sleep_difficulty_codes;
CREATE TABLE mimic_omop.sleep_difficulty_codes AS
SELECT concept_id
FROM omop.concept
WHERE vocabulary_id IN ('ICD9CM','ICD10CM')
  AND concept_code IN (
      'F51.01','F51.02','F51.03','F51.04','F51.09',
      'G47.00','G47.01','G47.09'
  );

DROP TABLE IF EXISTS mimic_omop.daytime_impairment_codes;
CREATE TABLE mimic_omop.daytime_impairment_codes AS
SELECT concept_id
FROM omop.concept
WHERE vocabulary_id IN ('ICD9CM','ICD10CM')
  AND concept_code IN (
      'F48.0','R53.83','R53.81','F32.0','F32.1','F32.9','R45.4','R40.0'
  );

Identify patient swith those diagnosis types

-- Patients with any sleep-difficulty ICD
DROP TABLE IF EXISTS mimic_omop.sleep_difficulty_patients;
CREATE TABLE mimic_omop.sleep_difficulty_patients AS
SELECT DISTINCT subject_id
FROM mimic_omop.diagnoses_mapped
WHERE concept_id IN (SELECT concept_id FROM mimic_omop.sleep_difficulty_codes);

-- Patients with any daytime-impairment ICD
DROP TABLE IF EXISTS mimic_omop.daytime_impairment_patients;
CREATE TABLE mimic_omop.daytime_impairment_patients AS
SELECT DISTINCT subject_id
FROM mimic_omop.diagnoses_mapped
WHERE concept_id IN (SELECT concept_id FROM mimic_omop.daytime_impairment_codes);

Identify patients with diffigulty and impairment
DROP TABLE IF EXISTS mimic_omop.ruleA_patients;
CREATE TABLE mimic_omop.ruleA_patients AS
SELECT d.subject_id
FROM mimic_omop.sleep_difficulty_patients d
JOIN mimic_omop.daytime_impairment_patients i
  ON d.subject_id = i.subject_id;

--Merge and label single patient-level table--
DROP TABLE IF EXISTS mimic_omop.insomnia_cohort;
CREATE TABLE mimic_omop.insomnia_cohort AS
SELECT
    p.subject_id,
    MAX(CASE WHEN f.source_rule = 'RuleA' THEN 1 ELSE 0 END) AS ruleA,
    MAX(CASE WHEN f.source_rule = 'RuleB' THEN 1 ELSE 0 END) AS ruleB,
    MAX(CASE WHEN f.source_rule = 'RuleC' THEN 1 ELSE 0 END) AS ruleC,
    CASE 
        WHEN MAX(CASE WHEN f.source_rule IN ('RuleA','RuleB','RuleC') THEN 1 ELSE 0 END) = 1
        THEN 1 ELSE 0
    END AS insomnia_flag
FROM mimic_omop.insomnia_patients_final f
JOIN mimic_omop.patients p ON p.subject_id = f.subject_id
GROUP BY p.subject_id;
