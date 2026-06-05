-- Migration: Create codex content assets table
-- Date: 2026-06-05

CREATE TABLE IF NOT EXISTS codex_content_assets (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  entity_id BIGINT REFERENCES codex_entities(id) ON DELETE CASCADE,
  asset_type TEXT NOT NULL,
  title TEXT,
  content TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  audience TEXT,
  spoiler_level TEXT NOT NULL DEFAULT 'spoiler_free',
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codex_content_assets_series ON codex_content_assets(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_content_assets_entity ON codex_content_assets(entity_id);

ALTER TABLE codex_content_assets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON codex_content_assets
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
