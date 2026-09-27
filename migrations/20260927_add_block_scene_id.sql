-- Add scene-level anchoring to SCE blocks.
-- A block with scene_id set is positioned inside that scene's row on the
-- timeline grid. A NULL scene_id keeps the existing state-level behaviour.

ALTER TABLE sce_blocks
  ADD COLUMN IF NOT EXISTS scene_id BIGINT REFERENCES sce_scenes(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_sce_blocks_scene_id ON sce_blocks(scene_id);
