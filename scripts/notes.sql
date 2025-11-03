CREATE SCHEMA IF NOT EXISTS kb;

-- sentence-level outputs from LLM
CREATE TABLE IF NOT EXISTS kb.note_sent_evidence (
  subject_id BIGINT,
  hadm_id    BIGINT,
  note_rowid BIGINT,     -- a surrogate row id we’ll assign in Python
  sent_id    INT,        -- sentence index within the note
  text_span  TEXT,
  asserts_sleep_difficulty BOOLEAN,
  asserts_daytime_impairment BOOLEAN,
  negated    BOOLEAN,
  temporality TEXT,      -- 'current' | 'historical' | 'uncertain'
  decided_by  TEXT DEFAULT 'llm',
  created_at  TIMESTAMP DEFAULT NOW()
);

-- materialized “set-style” evidence for reuse by rules (parallel to dx evidence)
CREATE TABLE IF NOT EXISTS kb.evd_note_sleep (
  subject_id BIGINT,
  hadm_id    BIGINT,
  note_rowid BIGINT,
  sent_id    INT,
  text_span  TEXT,
  negated    BOOLEAN,
  temporality TEXT
);

CREATE TABLE IF NOT EXISTS kb.evd_note_impair (
  subject_id BIGINT,
  hadm_id    BIGINT,
  note_rowid BIGINT,
  sent_id    INT,
  text_span  TEXT,
  negated    BOOLEAN,
  temporality TEXT
);
