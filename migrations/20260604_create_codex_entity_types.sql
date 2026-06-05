-- Migration: Create codex_entity_types table and seed default types
-- Date: 2026-06-04
-- Phase 1: Generic Codex Core Schema

CREATE TABLE IF NOT EXISTS codex_entity_types (
  id BIGSERIAL PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  name_singular TEXT NOT NULL,
  name_plural TEXT NOT NULL,
  icon TEXT,
  description TEXT,
  field_schema JSONB NOT NULL DEFAULT '{}',
  display_settings JSONB NOT NULL DEFAULT '{}',
  is_system_type BOOLEAN NOT NULL DEFAULT FALSE,
  is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default entity types
INSERT INTO codex_entity_types (key, name_singular, name_plural, icon, description, is_system_type, sort_order) VALUES
  ('character', 'Character', 'Characters', 'user', 'People, creatures, or sentient entities in the story', TRUE, 10),
  ('location', 'Location', 'Locations', 'map-pin', 'Places, regions, buildings, or environments', TRUE, 20),
  ('organisation', 'Organisation', 'Organisations', 'building', 'Groups, factions, guilds, or institutions', TRUE, 30),
  ('family', 'Family', 'Families', 'users', 'Family units, dynasties, or bloodlines', TRUE, 40),
  ('item', 'Item', 'Items', 'box', 'Objects, artifacts, weapons, or tools', TRUE, 50),
  ('lore', 'Lore', 'Lore', 'book-open', 'World rules, magic systems, history, or mythology', TRUE, 60),
  ('quest', 'Quest', 'Quests', 'compass', 'Plot threads, missions, or story arcs', TRUE, 70),
  ('journal', 'Journal', 'Journals', 'feather', 'Diaries, logs, notes, or personal writings', TRUE, 80),
  ('continuity_note', 'Continuity Note', 'Continuity Notes', 'alert-triangle', 'Continuity issues, plotholes, or tracking notes', TRUE, 90)
ON CONFLICT (key) DO NOTHING;
