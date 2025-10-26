-- Vocabulary table
CREATE TABLE omop.vocabulary (
  vocabulary_id VARCHAR(20) PRIMARY KEY,
  vocabulary_name VARCHAR(255),
  vocabulary_reference VARCHAR(255),
  vocabulary_version VARCHAR(255),
  vocabulary_concept_id INTEGER
);

-- Concept table
CREATE TABLE omop.concept (
  concept_id INTEGER PRIMARY KEY,
  concept_name VARCHAR(255),
  domain_id VARCHAR(50),
  vocabulary_id VARCHAR(20),
  concept_class_id VARCHAR(50),
  standard_concept CHAR(1),
  concept_code VARCHAR(50),
  valid_start_date DATE,
  valid_end_date DATE,
  invalid_reason CHAR(1)
);

-- Concept Relationship table
CREATE TABLE omop.concept_relationship (
  concept_id_1 INTEGER,
  concept_id_2 INTEGER,
  relationship_id VARCHAR(20),
  valid_start_date DATE,
  valid_end_date DATE,
  invalid_reason CHAR(1)
);

-- Concept Ancestor table
CREATE TABLE omop.concept_ancestor (
  ancestor_concept_id INTEGER,
  descendant_concept_id INTEGER,
  min_levels_of_separation INTEGER,
  max_levels_of_separation INTEGER
);

-- Concept Synonym table
CREATE TABLE omop.concept_synonym (
  concept_id INTEGER,
  concept_synonym_name VARCHAR(1000),
  language_concept_id INTEGER
);

-- Relationship table
CREATE TABLE omop.relationship (
  relationship_id VARCHAR(20) PRIMARY KEY,
  relationship_name VARCHAR(255),
  is_hierarchical CHAR(1),
  defines_ancestry CHAR(1),
  reverse_relationship_id VARCHAR(20),
  relationship_concept_id INTEGER
);
