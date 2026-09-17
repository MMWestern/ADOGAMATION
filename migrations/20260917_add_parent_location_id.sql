-- Migration: Add parent_location_id column to codex_entities
-- Run this in the Supabase SQL editor BEFORE deploying the code changes.
-- This migration is NOT destructive — existing located_in connections are preserved as backup.

-- Step 1: Add the column
ALTER TABLE codex_entities
ADD COLUMN IF NOT EXISTS parent_location_id BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL;

-- Step 2: Create index for efficient child queries
CREATE INDEX IF NOT EXISTS idx_codex_entities_parent_location
ON codex_entities(parent_location_id)
WHERE parent_location_id IS NOT NULL;

-- Step 3: Migrate existing located_in connections to the new column
-- Only migrates active, non-deleted connections for location entities
UPDATE codex_entities e
SET parent_location_id = c.target_entity_id
FROM codex_connections c
JOIN codex_relationship_types rt ON c.relationship_type_id = rt.id
WHERE c.source_entity_id = e.id
  AND rt.key = 'located_in'
  AND c.deleted_at IS NULL
  AND c.context_status != 'ended'
  AND e.deleted_at IS NULL
  AND e.entity_type_id = (SELECT id FROM codex_entity_types WHERE key = 'location' LIMIT 1)
  AND e.parent_location_id IS NULL; -- don't overwrite if already set

-- Step 4: Verify — check how many locations were migrated
-- SELECT count(*) FROM codex_entities WHERE parent_location_id IS NOT NULL;
