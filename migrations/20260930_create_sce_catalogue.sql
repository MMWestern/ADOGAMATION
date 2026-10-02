-- Story Block Catalogue — reusable bank of story possibilities.
--
-- Deliberately has no series_id: catalogue entries are shared prompts available
-- to every suitable project, unlike sce_assets which is the author's own
-- series-scoped idea bank. A catalogue entry is never edited when it becomes a
-- story block; the block stores a denormalised snapshot of the provenance
-- instead (see 20260930_add_block_catalogue_provenance.sql).
--
-- default_color follows the American spelling used by sce_layers.color and
-- sce_chapters.color rather than the brief's "default_colour".

CREATE TABLE IF NOT EXISTS sce_catalogue_entries (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  purpose TEXT,
  prompt_questions TEXT,
  default_color TEXT DEFAULT '#3b82f6',
  active BOOLEAN NOT NULL DEFAULT TRUE,
  is_favourite BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT sce_catalogue_entries_name_category_key UNIQUE (name, category)
);

CREATE INDEX IF NOT EXISTS idx_sce_catalogue_entries_category ON sce_catalogue_entries(category);
CREATE INDEX IF NOT EXISTS idx_sce_catalogue_entries_active ON sce_catalogue_entries(active);

ALTER TABLE sce_catalogue_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON sce_catalogue_entries FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);