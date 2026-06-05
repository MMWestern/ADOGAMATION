-- Migration: Create codex embeddings table for semantic search
-- Date: 2026-06-05
-- Phase 12: Semantic Retrieval

CREATE TABLE IF NOT EXISTS codex_embeddings (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  entity_id BIGINT REFERENCES codex_entities(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL DEFAULT 'entity_description',
  source_id BIGINT,
  content_text TEXT NOT NULL,
  embedding JSONB NOT NULL DEFAULT '[]',
  model TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codex_embeddings_series ON codex_embeddings(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_embeddings_entity ON codex_embeddings(entity_id);

ALTER TABLE codex_embeddings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_embeddings
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
