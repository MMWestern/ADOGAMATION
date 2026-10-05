-- Idea Notes: fast-capture notes from the mobile PWA.
-- Shared team model — any authenticated user can read/write all notes,
-- matching the "Authenticated full access" pattern used by every other table.
-- owner_id is stamped from auth.uid() for provenance, not access control.

CREATE TABLE IF NOT EXISTS idea_notes (
  id               BIGSERIAL PRIMARY KEY,
  owner_id         UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  series_id        BIGINT REFERENCES series(id) ON DELETE SET NULL,
  project_id       BIGINT REFERENCES projects(id) ON DELETE SET NULL,
  character_id     BIGINT REFERENCES codex_entities(id) ON DELETE SET NULL,
  category         TEXT NOT NULL CHECK (category IN ('character', 'story', 'world', 'general_idea')),
  title            TEXT,
  original_content TEXT NOT NULL,
  content          TEXT NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Provenance trigger: stamp owner_id from the JWT on insert.
CREATE OR REPLACE FUNCTION idea_notes_stamp_owner()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.owner_id IS NULL THEN
    NEW.owner_id := auth.uid();
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER idea_notes_before_insert
  BEFORE INSERT ON idea_notes
  FOR EACH ROW EXECUTE FUNCTION idea_notes_stamp_owner();

-- Keep updated_at fresh on every update.
CREATE OR REPLACE FUNCTION idea_notes_touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER idea_notes_before_update
  BEFORE UPDATE ON idea_notes
  FOR EACH ROW EXECUTE FUNCTION idea_notes_touch_updated_at();

-- Indexes for the common query paths.
CREATE INDEX idx_idea_notes_series    ON idea_notes (series_id);
CREATE INDEX idx_idea_notes_project   ON idea_notes (project_id);
CREATE INDEX idx_idea_notes_category  ON idea_notes (category);
CREATE INDEX idx_idea_notes_owner     ON idea_notes (owner_id);
CREATE INDEX idx_idea_notes_created   ON idea_notes (created_at DESC);
CREATE INDEX idx_idea_notes_updated   ON idea_notes (updated_at DESC);

-- RLS: shared team model — any authenticated user has full access.
ALTER TABLE idea_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated full access" ON idea_notes
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
