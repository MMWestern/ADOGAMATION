-- Migration: Create codex_relationship_types and codex_connections tables
-- Date: 2026-06-04
-- Phase 1: Generic Codex Core Schema

-- Relationship type definitions
CREATE TABLE IF NOT EXISTS codex_relationship_types (
  id BIGSERIAL PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  forward_label TEXT NOT NULL,
  inverse_label TEXT,
  is_directional BOOLEAN NOT NULL DEFAULT TRUE,
  description TEXT,
  allowed_source_types JSONB,
  allowed_target_types JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default relationship types
INSERT INTO codex_relationship_types (key, forward_label, inverse_label, is_directional) VALUES
  ('parent_of', 'Parent of', 'Child of', TRUE),
  ('child_of', 'Child of', 'Parent of', TRUE),
  ('member_of', 'Member of', 'Has member', TRUE),
  ('has_member', 'Has member', 'Member of', TRUE),
  ('located_in', 'Located in', 'Contains', TRUE),
  ('contains', 'Contains', 'Located in', TRUE),
  ('owns', 'Owns', 'Owned by', TRUE),
  ('owned_by', 'Owned by', 'Owns', TRUE),
  ('created', 'Created', 'Created by', TRUE),
  ('created_by', 'Created by', 'Created', TRUE),
  ('allied_with', 'Allied with', 'Allied with', FALSE),
  ('enemy_of', 'Enemy of', 'Enemy of', FALSE),
  ('knows', 'Knows', 'Known by', TRUE),
  ('related_to', 'Related to', 'Related to', FALSE)
ON CONFLICT (key) DO NOTHING;

-- Entity-to-entity connections
CREATE TABLE IF NOT EXISTS codex_connections (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  source_entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  target_entity_id BIGINT NOT NULL REFERENCES codex_entities(id) ON DELETE CASCADE,
  relationship_type_id BIGINT REFERENCES codex_relationship_types(id),
  label TEXT,
  inverse_label TEXT,
  description TEXT,
  is_secret BOOLEAN NOT NULL DEFAULT FALSE,
  visibility TEXT NOT NULL DEFAULT 'private',
  metadata JSONB NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  CHECK (source_entity_id <> target_entity_id)
);

CREATE INDEX IF NOT EXISTS idx_codex_connections_series ON codex_connections(series_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_source ON codex_connections(source_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_target ON codex_connections(target_entity_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_type ON codex_connections(relationship_type_id);
CREATE INDEX IF NOT EXISTS idx_codex_connections_deleted ON codex_connections(deleted_at);
