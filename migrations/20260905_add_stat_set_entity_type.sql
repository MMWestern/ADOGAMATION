-- Codex v2.1.1: Add stat_set entity type and field definitions
-- A stat set groups multiple canonical stats together (e.g., "Core Attributes" contains STR, DEX, CON, INT, CHA)
-- Date: 2026-09-05

-- Add stat_set entity type
INSERT INTO codex_entity_types (key, name_singular, name_plural, icon, description, is_system_type, is_enabled, sort_order) VALUES
  ('stat_set', 'Stat Set', 'Stat Sets', '📊', 'Groups of related stats (e.g., Core Attributes, Combat Stats)', FALSE, TRUE, 95)
ON CONFLICT (key) DO NOTHING;

-- Add field definitions for stat_set
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('stat_set', 'description', 'Description', 'long_text', 'General', 10, 'What this stat set represents', NULL),
  ('stat_set', 'system', 'System', 'entity_link', 'Links', 20, 'Parent system definition', '{"entity_type_key":"system_rule"}'),
  ('stat_set', 'display_order', 'Display Order', 'number', 'Display', 30, 'Ordering on character sheets', NULL)
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Add "member_of_stat_set" relationship type for linking stats to sets
INSERT INTO codex_relationship_types (key, forward_label, inverse_label, is_directional, description) VALUES
  ('member_of_stat_set', 'Member of', 'Contains', TRUE, 'Links a stat to a stat set')
ON CONFLICT (key) DO NOTHING;
