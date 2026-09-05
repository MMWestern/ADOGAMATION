-- Phase 4: Backfill appearances from existing entity_projects
-- Only backfills unambiguous data: entity linked to a project = entity appears in that book
-- Date: 2026-09-05

-- Step 1: Backfill codex_entity_appearances from codex_entity_projects
-- This is unambiguous: if an entity is linked to a project, it appears in that book
INSERT INTO codex_entity_appearances (entity_id, series_id, book_id, appearance_type, source)
SELECT
  ep.entity_id,
  e.series_id,
  ep.project_id,
  'appears',
  'backfill'
FROM codex_entity_projects ep
JOIN codex_entities e ON e.id = ep.entity_id AND e.deleted_at IS NULL
WHERE ep.project_id IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM codex_entity_appearances a
    WHERE a.entity_id = ep.entity_id
      AND a.book_id = ep.project_id
      AND a.appearance_type = 'appears'
  );

-- Step 2: Report backfill results
SELECT
  'Backfill complete' AS status,
  COUNT(*) AS total_appearances,
  COUNT(DISTINCT entity_id) AS unique_entities,
  COUNT(DISTINCT book_id) AS unique_books
FROM codex_entity_appearances
WHERE source = 'backfill';

-- Step 3: Verify no duplicates
SELECT
  entity_id,
  book_id,
  COUNT(*) AS duplicate_count
FROM codex_entity_appearances
GROUP BY entity_id, book_id, appearance_type
HAVING COUNT(*) > 1;
