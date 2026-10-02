-- Story Block Catalogue provenance on story blocks.
--
-- A denormalised snapshot taken at creation time. The brief requires the block to
-- keep its catalogue type so Story Mix can count it without manual tagging, even
-- after the author renames the block or the catalogue entry is later deactivated.
--
-- source_catalogue_id is ON DELETE SET NULL so retiring an entry never breaks a
-- block; the name and category columns keep the type countable either way.

ALTER TABLE sce_blocks
  ADD COLUMN IF NOT EXISTS source_catalogue_id BIGINT REFERENCES sce_catalogue_entries(id) ON DELETE SET NULL;

ALTER TABLE sce_blocks
  ADD COLUMN IF NOT EXISTS source_catalogue_name TEXT;

ALTER TABLE sce_blocks
  ADD COLUMN IF NOT EXISTS source_category TEXT;

CREATE INDEX IF NOT EXISTS idx_sce_blocks_source_catalogue ON sce_blocks(source_catalogue_id);
CREATE INDEX IF NOT EXISTS idx_sce_blocks_source_category ON sce_blocks(source_category);