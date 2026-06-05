-- Migration: Create codex mentions table
-- Date: 2026-06-05

CREATE TABLE IF NOT EXISTS codex_mentions (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  project_id BIGINT REFERENCES projects(id) ON DELETE CASCADE,
  document_id BIGINT REFERENCES documents(id) ON DELETE CASCADE,
  section_id BIGINT REFERENCES document_sections(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL,
  source_anchor JSONB NOT NULL DEFAULT '{}',
  matched_text TEXT,
  mention_method TEXT NOT NULL DEFAULT 'manual',
  confidence NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codex_mentions_series ON codex_mentions(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_mentions_entity ON codex_mentions(entity_id);

ALTER TABLE codex_mentions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_mentions
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
