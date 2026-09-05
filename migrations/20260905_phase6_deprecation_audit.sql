-- Phase 6: Deprecation audit
-- Measures usage of potentially redundant entity types
-- Date: 2026-09-05

-- 1. Relationship entity vs codex_connections
SELECT
  'relationship' AS entity_type,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'relationship') AND deleted_at IS NULL) AS entity_count,
  (SELECT COUNT(*) FROM codex_connections WHERE deleted_at IS NULL) AS connection_count,
  CASE
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'relationship') AND deleted_at IS NULL) = 0
    THEN 'SAFE TO DEPRECATE - No relationship entities exist'
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'relationship') AND deleted_at IS NULL) < 10
    THEN 'LOW USAGE - Consider migrating to connections'
    ELSE 'ACTIVE USAGE - Do not deprecate yet'
  END AS recommendation;

-- 2. Equipment entity vs Item entity
SELECT
  'equipment' AS entity_type,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'equipment') AND deleted_at IS NULL) AS equipment_count,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'item') AND deleted_at IS NULL) AS item_count,
  CASE
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'equipment') AND deleted_at IS NULL) = 0
    THEN 'SAFE TO DEPRECATE - No equipment entities exist'
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'equipment') AND deleted_at IS NULL) < 10
    THEN 'LOW USAGE - Consider migrating to item with sub-types'
    ELSE 'ACTIVE USAGE - Do not deprecate yet'
  END AS recommendation;

-- 3. Quest vs Story Thread
SELECT
  'quest' AS entity_type,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'quest') AND deleted_at IS NULL) AS quest_count,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'story_thread') AND deleted_at IS NULL) AS story_thread_count,
  CASE
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'quest') AND deleted_at IS NULL) = 0
    THEN 'SAFE TO DEPRECATE - No quest entities exist'
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'quest') AND deleted_at IS NULL) < 10
    THEN 'LOW USAGE - Consider merging with story_thread'
    ELSE 'ACTIVE USAGE - Keep separate (quest = in-world, story_thread = author-facing)'
  END AS recommendation;

-- 4. Lore entity usage (broad catch-all)
SELECT
  'lore' AS entity_type,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'lore') AND deleted_at IS NULL) AS lore_count,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id IN (
    SELECT id FROM codex_entity_types WHERE key IN ('history_era', 'mystery', 'glossary', 'document')
  ) AND deleted_at IS NULL) AS specialized_count,
  CASE
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'lore') AND deleted_at IS NULL) < 10
    THEN 'LOW USAGE - Lore is flexible residual type'
    ELSE 'ACTIVE USAGE - Lore serves as flexible catch-all'
  END AS recommendation;

-- 5. Magic System vs Power System
SELECT
  'magic_system' AS entity_type,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'magic_system') AND deleted_at IS NULL) AS magic_count,
  (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'power_system') AND deleted_at IS NULL) AS power_count,
  CASE
    WHEN (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'magic_system') AND deleted_at IS NULL) = 0
      AND (SELECT COUNT(*) FROM codex_entities WHERE entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'power_system') AND deleted_at IS NULL) = 0
    THEN 'BOTH EMPTY - Consider merging in future'
    ELSE 'ACTIVE USAGE - Keep separate for now'
  END AS recommendation;

-- 6. Summary of all entity type usage
SELECT
  et.key AS entity_type_key,
  et.name_singular,
  COUNT(e.id) AS entity_count,
  CASE
    WHEN COUNT(e.id) = 0 THEN 'UNUSED'
    WHEN COUNT(e.id) < 5 THEN 'LOW'
    WHEN COUNT(e.id) < 20 THEN 'MODERATE'
    ELSE 'ACTIVE'
  END AS usage_level
FROM codex_entity_types et
LEFT JOIN codex_entities e ON e.entity_type_id = et.id AND e.deleted_at IS NULL
GROUP BY et.key, et.name_singular
ORDER BY entity_count DESC;
