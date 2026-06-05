-- Phase 4 test: Insert test entities into codex_entities
-- This script auto-detects your series_id and inserts test data

-- Insert test character
INSERT INTO codex_entities (series_id, entity_type_id, name, summary, description, color, scope, custom_data)
SELECT
  s.id,
  t.id,
  'Test Character',
  'A test character for Phase 4 verification',
  'Full description of the test character goes here.',
  '#3b82f6',
  'series',
  '{"role_archetype": "Protagonist", "archetype": "The Hero"}'::jsonb
FROM series s
CROSS JOIN codex_entity_types t
WHERE t.key = 'character'
LIMIT 1;

-- Insert test location
INSERT INTO codex_entities (series_id, entity_type_id, name, summary, description, color, scope, custom_data)
SELECT
  s.id,
  t.id,
  'Test Location',
  'A test location for Phase 4 verification',
  'Full description of the test location.',
  '#22c55e',
  'book',
  '{"type": "City", "significance": "Main setting"}'::jsonb
FROM series s
CROSS JOIN codex_entity_types t
WHERE t.key = 'location'
LIMIT 1;

-- Insert test lore
INSERT INTO codex_entities (series_id, entity_type_id, name, summary, description, scope)
SELECT
  s.id,
  t.id,
  'Test Lore',
  'A test lore entry for Phase 4',
  'Magic system rules and world history.',
  'series'
FROM series s
CROSS JOIN codex_entity_types t
WHERE t.key = 'lore'
LIMIT 1;

-- Verify what was inserted
SELECT ce.id, ce.name, cet.key as type, ce.scope, ce.color
FROM codex_entities ce
JOIN codex_entity_types cet ON cet.id = ce.entity_type_id
ORDER BY ce.created_at DESC
LIMIT 10;
