-- Migration: Create codex_tags and codex_entity_tags tables
-- Date: 2026-06-04
-- Phase 1: Generic Codex Core Schema

CREATE TABLE IF NOT EXISTS codex_tags (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(series_id, slug)
);

CREATE INDEX IF NOT EXISTS idx_codex_tags_series ON codex_tags(series_id);

CREATE TABLE IF NOT EXISTS codex_entity_tags (
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  tag_id BIGINT NOT NULL REFERENCES codex_tags(id) ON DELETE CASCADE,
  PRIMARY KEY(entity_id, tag_id)
);

CREATE INDEX IF NOT EXISTS idx_codex_entity_tags_entity ON codex_entity_tags(entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_tags_tag ON codex_entity_tags(tag_id);
