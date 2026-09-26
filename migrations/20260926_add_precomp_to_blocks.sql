-- Precomps: add composition link to blocks
-- Run this in Supabase SQL editor

ALTER TABLE sce_blocks
ADD COLUMN IF NOT EXISTS precomp_composition_id BIGINT REFERENCES sce_compositions(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_sce_blocks_precomp ON sce_blocks(precomp_composition_id)
WHERE precomp_composition_id IS NOT NULL;
