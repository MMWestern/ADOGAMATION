-- Migration: Create codex_entities table with indexes
-- Date: 2026-06-04
-- Phase 1: Generic Codex Core Schema

CREATE TABLE IF NOT EXISTS codex_entities (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  entity_type_id BIGINT NOT NULL REFERENCES codex_entity_types(id),
  name TEXT NOT NULL,
  slug TEXT,
  aliases TEXT[] NOT NULL DEFAULT '{}',
  summary TEXT,
  description TEXT,
  image_url TEXT,
  color VARCHAR(7),
  scope TEXT NOT NULL DEFAULT 'series',
  status TEXT NOT NULL DEFAULT 'active',
  visibility TEXT NOT NULL DEFAULT 'private',
  canon_status TEXT NOT NULL DEFAULT 'draft',
  public_summary TEXT,
  marketing_summary TEXT,
  web_slug TEXT,
  web_visibility TEXT NOT NULL DEFAULT 'private',
  spoiler_level TEXT NOT NULL DEFAULT 'author_only',
  featured BOOLEAN NOT NULL DEFAULT FALSE,
  web_metadata JSONB NOT NULL DEFAULT '{}',
  sort_order INTEGER NOT NULL DEFAULT 0,
  custom_data JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- Indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_codex_entities_series_id ON codex_entities(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_entities_type_id ON codex_entities(entity_type_id);
CREATE INDEX IF NOT EXISTS idx_codex_entities_name ON codex_entities(name);
CREATE INDEX IF NOT EXISTS idx_codex_entities_slug ON codex_entities(slug);
CREATE INDEX IF NOT EXISTS idx_codex_entities_deleted_at ON codex_entities(deleted_at);
CREATE INDEX IF NOT EXISTS idx_codex_entities_aliases_gin ON codex_entities USING GIN (aliases);
CREATE INDEX IF NOT EXISTS idx_codex_entities_custom_data_gin ON codex_entities USING GIN (custom_data);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_codex_entities_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_codex_entities_updated_at ON codex_entities;
CREATE TRIGGER trg_codex_entities_updated_at
  BEFORE UPDATE ON codex_entities
  FOR EACH ROW
  EXECUTE FUNCTION update_codex_entities_updated_at();
