-- Migration: Create codex_entity_projects (book assignment) table
-- Date: 2026-06-04
-- Phase 1: Generic Codex Core Schema

CREATE TABLE IF NOT EXISTS codex_entity_projects (
  id BIGSERIAL PRIMARY KEY,
  entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(entity_id, project_id)
);

CREATE INDEX IF NOT EXISTS idx_codex_entity_projects_entity ON codex_entity_projects(entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_entity_projects_project ON codex_entity_projects(project_id);
