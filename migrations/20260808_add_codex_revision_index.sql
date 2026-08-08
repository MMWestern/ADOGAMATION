-- Stage 1A: Add index for efficient revision queries
-- World Builder implementation plan

CREATE INDEX IF NOT EXISTS idx_codex_revisions_entity_created
  ON codex_entity_revisions(entity_id, created_at DESC);
