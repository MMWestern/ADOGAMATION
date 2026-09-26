-- Chapter strip: chapters and scenes tables

-- Chapters span one or more states
CREATE TABLE IF NOT EXISTS sce_chapters (
  id BIGSERIAL PRIMARY KEY,
  composition_id BIGINT NOT NULL REFERENCES sce_compositions(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'Untitled Chapter',
  start_state INT NOT NULL DEFAULT 1,
  end_state INT NOT NULL DEFAULT 1,
  sort_order INT DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_chapters_composition ON sce_chapters(composition_id);

-- Scenes belong to chapters
CREATE TABLE IF NOT EXISTS sce_scenes (
  id BIGSERIAL PRIMARY KEY,
  chapter_id BIGINT NOT NULL REFERENCES sce_chapters(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT 'Untitled Scene',
  sort_order INT DEFAULT 0,
  before_text TEXT,
  what_happens TEXT,
  after_text TEXT,
  next_text TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_sce_scenes_chapter ON sce_scenes(chapter_id);

-- RLS
ALTER TABLE sce_chapters ENABLE ROW LEVEL SECURITY;
ALTER TABLE sce_scenes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON sce_chapters FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Authenticated full access" ON sce_scenes FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);