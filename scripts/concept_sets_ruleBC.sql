-- ======================================================
-- Seed drugs
-- ======================================================

TRUNCATE kb.concept_seed;

INSERT INTO kb.concept_seed VALUES
('primary_drug','RxNorm','Zolpidem'),
('primary_drug','RxNorm','Eszopiclone'),
('primary_drug','RxNorm','Temazepam'),
('primary_drug','RxNorm','Triazolam'),
('primary_drug','RxNorm','Suvorexant');

INSERT INTO kb.concept_seed VALUES
('secondary_drug','RxNorm','Melatonin'),
('secondary_drug','RxNorm','Trazodone'),
('secondary_drug','RxNorm','Doxepin'),
('secondary_drug','RxNorm','Mirtazapine'),
('secondary_drug','RxNorm','Quetiapine');

-- ======================================================
-- Expand drug concept sets
-- ======================================================

TRUNCATE kb.concept_set;

INSERT INTO kb.concept_set (set_name, concept_id)
SELECT s.set_name, ca.descendant_concept_id
FROM kb.concept_seed s
JOIN omop.concept c
  ON c.vocabulary_id = s.vocabulary_id
 AND c.concept_name  = s.concept_code
JOIN omop.concept_ancestor ca
  ON ca.ancestor_concept_id = c.concept_id

UNION

SELECT s.set_name, c.concept_id
FROM kb.concept_seed s
JOIN omop.concept c
  ON c.vocabulary_id = s.vocabulary_id
 AND c.concept_name  = s.concept_code;

-- ======================================================
-- Prescription evidence
-- ======================================================

DROP TABLE IF EXISTS kb.evd_rx_primary;
CREATE TABLE kb.evd_rx_primary AS
SELECT DISTINCT
  p.subject_id,
  p.hadm_id,
  'primary_drug'::text AS set_name
FROM mimic_omop.prescriptions p
WHERE LOWER(p.drug) SIMILAR TO
  '%(zolpidem|eszopiclone|temazepam|triazolam|suvorexant)%';

DROP TABLE IF EXISTS kb.evd_rx_secondary;
CREATE TABLE kb.evd_rx_secondary AS
SELECT DISTINCT
  p.subject_id,
  p.hadm_id,
  'secondary_drug'::text AS set_name
FROM mimic_omop.prescriptions p
WHERE LOWER(p.drug) SIMILAR TO
  '%(melatonin|trazodone|doxepin|mirtazapine|quetiapine)%';

-- ======================================================
-- Rules B and C
-- ======================================================

DROP TABLE IF EXISTS kb.ruleB;
CREATE TABLE kb.ruleB AS
SELECT DISTINCT subject_id
FROM kb.evd_rx_primary;

DROP TABLE IF EXISTS kb.ruleC;
CREATE TABLE kb.ruleC AS
SELECT DISTINCT s.subject_id
FROM kb.evd_rx_secondary s
WHERE s.subject_id IN (
  SELECT subject_id FROM kb.evd_dx_sleep
  UNION
  SELECT subject_id FROM kb.evd_dx_impair
);

-- ======================================================
-- Unified cohort table
-- ======================================================

DROP TABLE IF EXISTS mimic_omop.insomnia_cohort;

CREATE TABLE mimic_omop.insomnia_cohort AS
SELECT
  p.subject_id,
  p.gender,
  p.anchor_age,
  (a.subject_id IS NOT NULL) AS ruleA,
  (b.subject_id IS NOT NULL) AS ruleB,
  (c.subject_id IS NOT NULL) AS ruleC,
  (
    a.subject_id IS NOT NULL
    OR b.subject_id IS NOT NULL
    OR c.subject_id IS NOT NULL
  ) AS insomnia_flag
FROM mimic_omop.patients p
LEFT JOIN kb.ruleA a
  ON p.subject_id = a.subject_id
LEFT JOIN kb.ruleB b
  ON p.subject_id = b.subject_id
LEFT JOIN kb.ruleC c
  ON p.subject_id = c.subject_id;
