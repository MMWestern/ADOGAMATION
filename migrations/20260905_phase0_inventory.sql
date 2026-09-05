-- Phase 0: Database Inventory
-- Run this in Supabase SQL Editor to snapshot current state before v2 migration
-- Date: 2026-09-05

-- 1. Row counts for all codex tables
SELECT 'codex_entity_types' AS table_name, COUNT(*) AS row_count FROM codex_entity_types
UNION ALL SELECT 'codex_entities', COUNT(*) FROM codex_entities
UNION ALL SELECT 'codex_entity_projects', COUNT(*) FROM codex_entity_projects
UNION ALL SELECT 'codex_relationship_types', COUNT(*) FROM codex_relationship_types
UNION ALL SELECT 'codex_connections', COUNT(*) FROM codex_connections
UNION ALL SELECT 'codex_tags', COUNT(*) FROM codex_tags
UNION ALL SELECT 'codex_entity_tags', COUNT(*) FROM codex_entity_tags
UNION ALL SELECT 'codex_entity_revisions', COUNT(*) FROM codex_entity_revisions
UNION ALL SELECT 'codex_calendars', COUNT(*) FROM codex_calendars
UNION ALL SELECT 'codex_events', COUNT(*) FROM codex_events
UNION ALL SELECT 'codex_event_entities', COUNT(*) FROM codex_event_entities
UNION ALL SELECT 'codex_timelines', COUNT(*) FROM codex_timelines
UNION ALL SELECT 'codex_timeline_events', COUNT(*) FROM codex_timeline_events
UNION ALL SELECT 'codex_content_assets', COUNT(*) FROM codex_content_assets
UNION ALL SELECT 'codex_embeddings', COUNT(*) FROM codex_embeddings
UNION ALL SELECT 'codex_mentions', COUNT(*) FROM codex_mentions
UNION ALL SELECT 'codex_ai_suggestions', COUNT(*) FROM codex_ai_suggestions
UNION ALL SELECT 'codex_continuity_findings', COUNT(*) FROM codex_continuity_findings
UNION ALL SELECT 'codex_format_presets', COUNT(*) FROM codex_format_presets
ORDER BY table_name;

-- 2. Entity type distribution
SELECT
  et.key AS entity_type_key,
  et.name_singular,
  COUNT(e.id) AS entity_count
FROM codex_entity_types et
LEFT JOIN codex_entities e ON e.entity_type_id = et.id AND e.deleted_at IS NULL
GROUP BY et.key, et.name_singular
ORDER BY entity_count DESC;

-- 3. Connection type distribution
SELECT
  rt.key AS relationship_type_key,
  rt.forward_label,
  COUNT(c.id) AS connection_count
FROM codex_relationship_types rt
LEFT JOIN codex_connections c ON c.relationship_type_id = rt.id AND c.deleted_at IS NULL
GROUP BY rt.key, rt.forward_label
ORDER BY connection_count DESC;

-- 4. Series with most entities
SELECT
  s.id AS series_id,
  s.name AS series_name,
  COUNT(e.id) AS entity_count
FROM series s
LEFT JOIN codex_entities e ON e.series_id = s.id AND e.deleted_at IS NULL
GROUP BY s.id, s.name
ORDER BY entity_count DESC
LIMIT 10;

-- 5. Patrick's Part-Time Universe data (pilot dataset)
-- Replace <PATRICK_SERIES_ID> with the actual series ID
-- SELECT 'Patrick entities' AS metric, COUNT(*) FROM codex_entities WHERE series_id = <PATRICK_SERIES_ID> AND deleted_at IS NULL;
-- SELECT 'Patrick connections' AS metric, COUNT(*) FROM codex_connections WHERE series_id = <PATRICK_SERIES_ID> AND deleted_at IS NULL;

-- 6. Schema snapshot - all codex table columns
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name LIKE 'codex_%'
ORDER BY table_name, ordinal_position;

-- 7. Index snapshot
SELECT
  tablename,
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename LIKE 'codex_%'
ORDER BY tablename, indexname;

-- 8. RLS policies
SELECT
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename LIKE 'codex_%'
ORDER BY tablename, policyname;
