TRUNCATE kb.concept_seed;

-- Primary insomnia drugs (RxNorm)
INSERT INTO kb.concept_seed VALUES
('primary_drug','RxNorm','Zolpidem'),
('primary_drug','RxNorm','Eszopiclone'),
('primary_drug','RxNorm','Temazepam'),
('primary_drug','RxNorm','Triazolam'),
('primary_drug','RxNorm','Suvorexant');

-- Secondary insomnia drugs (RxNorm)
INSERT INTO kb.concept_seed VALUES
('secondary_drug','RxNorm','Melatonin'),
('secondary_drug','RxNorm','Trazodone'),
('secondary_drug','RxNorm','Doxepin'),
('secondary_drug','RxNorm','Mirtazapine'),
('secondary_drug','RxNorm','Quetiapine');

-- Re-expand
TRUNCATE kb.concept_set;
INSERT INTO kb.concept_set
SELECT s.set_name, ca.descendant_concept_id
FROM kb.concept_seed s
JOIN omop.concept c ON c.vocabulary_id=s.vocabulary_id AND c.concept_name=s.concept_code
JOIN omop.concept_ancestor ca ON ca.ancestor_concept_id=c.concept_id
UNION
SELECT s.set_name, c.concept_id
FROM kb.concept_seed s
JOIN omop.concept c ON c.vocabulary_id=s.vocabulary_id AND c.concept_name=s.concept_code;


-- Evidence from prescriptions table (by mapped concept_id if you have RxNorm)
DROP TABLE IF EXISTS kb.evd_rx_primary;
CREATE TABLE kb.evd_rx_primary AS
SELECT p.subject_id, p.hadm_id, 'primary_drug'::text AS set_name
FROM mimic_omop.prescriptions p
JOIN kb.concept_set s ON s.set_name='primary_drug'
-- placeholder matching logic if your prescriptions don't have concept_id:
WHERE LOWER(p.drug) SIMILAR TO '%(zolpidem|eszopiclone|temazepam|triazolam|suvorexant)%';

DROP TABLE IF EXISTS kb.evd_rx_secondary;
CREATE TABLE kb.evd_rx_secondary AS
SELECT p.subject_id, p.hadm_id, 'secondary_drug'::text AS set_name
FROM mimic_omop.prescriptions p
JOIN kb.concept_set s ON s.set_name='secondary_drug'
WHERE LOWER(p.drug) SIMILAR TO '%(melatonin|trazodone|doxepin|mirtazapine|quetiapine)%';

-- Rule B: any primary drug
DROP TABLE IF EXISTS kb.ruleB;
CREATE TABLE kb.ruleB AS
SELECT DISTINCT subject_id FROM kb.evd_rx_primary;

-- Rule C: secondary drug + (sleep difficulty OR impairment)
DROP TABLE IF EXISTS kb.ruleC;
CREATE TABLE kb.ruleC AS
SELECT DISTINCT s.subject_id
FROM kb.evd_rx_secondary s
WHERE s.subject_id IN (
  SELECT subject_id FROM kb.evd_dx_sleep
  UNION
  SELECT subject_id FROM kb.evd_dx_impair
);

--Unified explainable cohort table--
DROP TABLE IF EXISTS mimic_omop.insomnia_cohort;

CREATE TABLE mimic_omop.insomnia_cohort AS
SELECT 
    p.subject_id,
    p.gender,
    p.anchor_age,
    CASE WHEN a.subject_id IS NOT NULL THEN 1 ELSE 0 END AS ruleA,
    CASE WHEN b.subject_id IS NOT NULL THEN 1 ELSE 0 END AS ruleB,
    CASE WHEN c.subject_id IS NOT NULL THEN 1 ELSE 0 END AS ruleC,
    CASE 
        WHEN a.subject_id IS NOT NULL 
          OR b.subject_id IS NOT NULL 
          OR c.subject_id IS NOT NULL 
        THEN 1 ELSE 0 END AS insomnia_flag
FROM mimic_omop.patients p
LEFT JOIN kb.ruleA a ON p.subject_id = a.subject_id
LEFT JOIN kb.ruleB b ON p.subject_id = b.subject_id
LEFT JOIN kb.ruleC c ON p.subject_id = c.subject_id;

