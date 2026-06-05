-- Migration: Create codex_entity_revisions table
-- Date: 2026-06-04
-- Phase 1: Generic Codex Core Schema

CREATE TABLE IF NOT EXISTS codex_entity_revisions (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  revision_number INTEGER NOT NULL,
  snapshot JSONB NOT NULL,
  change_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_codex_entity_revisions_entity ON codex_entity_revisions(entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_revisions_number ON codex_entity_revisions(entity_id, revision_number);
