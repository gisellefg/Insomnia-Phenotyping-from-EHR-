-- Create a place to store seeds and expanded sets
CREATE SCHEMA IF NOT EXISTS kb;

-- Seed codes you curate (few, readable codes)
CREATE TABLE IF NOT EXISTS kb.concept_seed (
  set_name      TEXT,
  vocabulary_id TEXT,
  concept_code  TEXT
);

-- Expanded concept sets (after pulling descendants)
CREATE TABLE IF NOT EXISTS kb.concept_set (
  set_name  TEXT,
  concept_id BIGINT
);



-- See codes -- 
-- Wipe previous seeds if any
TRUNCATE kb.concept_seed;

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

-- (Optional) Sleep difficulty ICD-9-CM seeds (add if your data has ICD9)
INSERT INTO kb.concept_seed VALUES
('sleep_difficulty','ICD9CM','780.51'),  -- Insomnia with sleep apnea, etc. adjust as needed
('sleep_difficulty','ICD9CM','780.52'),  -- Insomnia, unspecified
('sleep_difficulty','ICD9CM','307.42');  -- Persistent disorder of initiating/maintaining sleep

-- Daytime impairment (starter examples; extend per your paper)
INSERT INTO kb.concept_seed VALUES
('daytime_impairment','ICD10CM','R53.81'),  -- other malaise
('daytime_impairment','ICD10CM','R53.83'),  -- other fatigue
('daytime_impairment','ICD10CM','R45.4');   -- irritability

-- (Optional ICD-9-CM counterparts)
INSERT INTO kb.concept_seed VALUES
('daytime_impairment','ICD9CM','780.79'),  -- other malaise and fatigue
('daytime_impairment','ICD9CM','799.51');  -- attention or concentration deficit (non-specific)

--Build the expanded sets with concept_ancestor--
TRUNCATE kb.concept_set;

INSERT INTO kb.concept_set (set_name, concept_id)
-- include descendants of each seed
SELECT s.set_name, ca.descendant_concept_id
FROM kb.concept_seed s
JOIN omop.concept c
  ON c.vocabulary_id = s.vocabulary_id
 AND c.concept_code  = s.concept_code
JOIN omop.concept_ancestor ca
  ON ca.ancestor_concept_id = c.concept_id

UNION

-- include the seed concepts themselves
SELECT s.set_name, c.concept_id
FROM kb.concept_seed s
JOIN omop.concept c
  ON c.vocabulary_id = s.vocabulary_id
 AND c.concept_code  = s.concept_code;

-- Evidence tables --
-- Evidence: diagnoses that match each set
DROP TABLE IF EXISTS kb.evd_dx_sleep;
CREATE TABLE kb.evd_dx_sleep AS
SELECT d.subject_id, d.hadm_id, d.concept_id, 'sleep_difficulty'::text AS set_name
FROM mimic_omop.diagnoses_mapped d
JOIN kb.concept_set s
  ON s.concept_id = d.concept_id
WHERE s.set_name='sleep_difficulty';

DROP TABLE IF EXISTS kb.evd_dx_impair;
CREATE TABLE kb.evd_dx_impair AS
SELECT d.subject_id, d.hadm_id, d.concept_id, 'daytime_impairment'::text AS set_name
FROM mimic_omop.diagnoses_mapped d
JOIN kb.concept_set s
  ON s.concept_id = d.concept_id
WHERE s.set_name='daytime_impairment';

-- Rule A = patients who have BOTH evidences somewhere in their record
DROP TABLE IF EXISTS kb.ruleA;
CREATE TABLE kb.ruleA AS
SELECT DISTINCT a.subject_id
FROM kb.evd_dx_sleep a
JOIN kb.evd_dx_impair b USING (subject_id);

-- Check counts
SELECT 'sleep_evd' AS what, COUNT(DISTINCT subject_id) FROM kb.evd_dx_sleep
UNION ALL
SELECT 'impair_evd', COUNT(DISTINCT subject_id) FROM kb.evd_dx_impair
UNION ALL
SELECT 'ruleA_patients', COUNT(*) FROM kb.ruleA;

