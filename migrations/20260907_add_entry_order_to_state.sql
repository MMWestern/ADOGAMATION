-- Add entry_order column to codex_entity_state
-- This column determines ordering of multiple state changes within the same chapter
-- B1 Ch7 / entry 1 / Health = 100
-- B1 Ch7 / entry 2 / Health = 42
-- B1 Ch7 / entry 3 / Health = 18
-- B1 Ch7 / entry 4 / Health = 75

ALTER TABLE codex_entity_state ADD COLUMN IF NOT EXISTS entry_order INTEGER DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_state_entry_order 
  ON codex_entity_state(subject_entity_id, property_key, entry_order);

-- Backfill existing records with entry_order = 1
UPDATE codex_entity_state SET entry_order = 1 WHERE entry_order IS NULL;
