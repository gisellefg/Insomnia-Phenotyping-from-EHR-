-- ======================================================
-- Schema and tables
-- ======================================================

CREATE SCHEMA IF NOT EXISTS kb;

CREATE TABLE IF NOT EXISTS kb.concept_seed (
  set_name      TEXT,
  vocabulary_id TEXT,
  concept_code  TEXT
);

CREATE TABLE IF NOT EXISTS kb.concept_set (
  set_name   TEXT,
  concept_id BIGINT
);

TRUNCATE kb.concept_seed;
TRUNCATE kb.concept_set;

-- ======================================================
-- Seed codes
-- ======================================================

-- Sleep difficulty (ICD-10-CM)
INSERT INTO kb.concept_seed VALUES
('sleep_difficulty','ICD10CM','F51.01'),
('sleep_difficulty','ICD10CM','F51.02'),
('sleep_difficulty','ICD10CM','F51.03'),
('sleep_difficulty','ICD10CM','F51.04'),
('sleep_difficulty','ICD10CM','F51.09'),
('sleep_difficulty','ICD10CM','G47.00'),
('sleep_difficulty','ICD10CM','G47.01'),
('sleep_difficulty','ICD10CM','G47.09');

-- Sleep difficulty (ICD-9-CM)
INSERT INTO kb.concept_seed VALUES
('sleep_difficulty','ICD9CM','780.51'),
('sleep_difficulty','ICD9CM','780.52'),
('sleep_difficulty','ICD9CM','307.42');

-- Daytime impairment (ICD-10-CM)
INSERT INTO kb.concept_seed VALUES
('daytime_impairment','ICD10CM','R53.81'),
('daytime_impairment','ICD10CM','R53.83'),
('daytime_impairment','ICD10CM','R45.4');

-- Daytime impairment (ICD-9-CM)
INSERT INTO kb.concept_seed VALUES
('daytime_impairment','ICD9CM','780.79'),
('daytime_impairment','ICD9CM','799.51');

-- ======================================================
-- Expand concept sets using concept_ancestor
-- ======================================================

INSERT INTO kb.concept_set (set_name, concept_id)
SELECT s.set_name, ca.descendant_concept_id
FROM kb.concept_seed s
JOIN omop.concept c
  ON c.vocabulary_id = s.vocabulary_id
 AND c.concept_code  = s.concept_code
JOIN omop.concept_ancestor ca
  ON ca.ancestor_concept_id = c.concept_id

UNION

SELECT s.set_name, c.concept_id
FROM kb.concept_seed s
JOIN omop.concept c
  ON c.vocabulary_id = s.vocabulary_id
 AND c.concept_code  = s.concept_code;

-- ======================================================
-- Diagnosis evidence
-- ======================================================

DROP TABLE IF EXISTS kb.evd_dx_sleep;
CREATE TABLE kb.evd_dx_sleep AS
SELECT d.subject_id, d.hadm_id, d.concept_id,
       'sleep_difficulty'::text AS set_name
FROM mimic_omop.diagnoses_mapped d
JOIN kb.concept_set s
  ON s.concept_id = d.concept_id
WHERE s.set_name = 'sleep_difficulty';

DROP TABLE IF EXISTS kb.evd_dx_impair;
CREATE TABLE kb.evd_dx_impair AS
SELECT d.subject_id, d.hadm_id, d.concept_id,
       'daytime_impairment'::text AS set_name
FROM mimic_omop.diagnoses_mapped d
JOIN kb.concept_set s
  ON s.concept_id = d.concept_id
WHERE s.set_name = 'daytime_impairment';

-- ======================================================
-- Rule A
-- ======================================================

DROP TABLE IF EXISTS kb.ruleA;
CREATE TABLE kb.ruleA AS
SELECT DISTINCT a.subject_id
FROM kb.evd_dx_sleep a
JOIN kb.evd_dx_impair b
  ON a.subject_id = b.subject_id;

-- ======================================================
-- Counts
-- ======================================================

SELECT 'sleep_evd' AS what, COUNT(DISTINCT subject_id)
FROM kb.evd_dx_sleep
UNION ALL
SELECT 'impair_evd', COUNT(DISTINCT subject_id)
FROM kb.evd_dx_impair
UNION ALL
SELECT 'ruleA_patients', COUNT(*)
FROM kb.ruleA;

-- ======================================================
-- SNOMED-based expansions
-- ======================================================

INSERT INTO mimic_omop.sleep_difficulty_codes (concept_id)
SELECT x.concept_id
FROM (VALUES
  (42538607),(43021812),(43021860),(43020464),(43020467),
  (37110488),(37166347),(44784625),(1340379),(444300),
  (4243368),(436962),(37016173),(37117120),(439013),
  (436681),(763092),(37397765),(434172),(4012514),
  (4282607),(4182361),(4102985),(440082),(4215402),
  (4138617),(4228217),(37161157),(434918)
) AS x(concept_id)
LEFT JOIN mimic_omop.sleep_difficulty_codes s
  ON s.concept_id = x.concept_id
WHERE s.concept_id IS NULL;

CREATE TABLE IF NOT EXISTS mimic_omop.daytime_impairment_codes (
  concept_id INTEGER PRIMARY KEY
);

INSERT INTO mimic_omop.daytime_impairment_codes (concept_id)
SELECT x.concept_id
FROM (VALUES
  (43530733),(4108537),(4043562),(4044238),(4043563),(4044239),
  (438134),(37016174),(434891),(436669),(4143701),(4047912),
  (439150),(43531627),(40483183),(40482713),(434904),
  (4262584),(443528),(4158978),(4302044),(437260)
) AS x(concept_id)
LEFT JOIN mimic_omop.daytime_impairment_codes d
  ON d.concept_id = x.concept_id
WHERE d.concept_id IS NULL;

-- ======================================================
-- Rebuild evidence using SNOMED sets
-- ======================================================

DROP TABLE IF EXISTS kb.evd_dx_sleep;
CREATE TABLE kb.evd_dx_sleep AS
SELECT DISTINCT d.subject_id, d.hadm_id, d.concept_id,
       'sleep_difficulty'::text AS set_name
FROM mimic_omop.diagnoses_mapped d
JOIN mimic_omop.sleep_difficulty_codes s
  ON d.concept_id = s.concept_id;

DROP TABLE IF EXISTS kb.evd_dx_impair;
CREATE TABLE kb.evd_dx_impair AS
SELECT DISTINCT d.subject_id, d.hadm_id, d.concept_id,
       'daytime_impairment'::text AS set_name
FROM mimic_omop.diagnoses_mapped d
JOIN mimic_omop.daytime_impairment_codes i
  ON d.concept_id = i.concept_id;

-- ======================================================
-- Update cohort table
-- ======================================================

ALTER TABLE mimic_omop.insomnia_cohort
  ALTER COLUMN rule_a TYPE boolean
  USING rule_a::boolean;

UPDATE mimic_omop.insomnia_cohort
SET rule_a = FALSE;

UPDATE mimic_omop.insomnia_cohort c
SET rule_a = TRUE
FROM kb.ruleA r
WHERE c.subject_id = r.subject_id;
