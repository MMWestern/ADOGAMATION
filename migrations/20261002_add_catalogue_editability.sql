-- Editable Catalogue entries with per-author ownership.
--
-- The seeded bank shipped by 20260930_seed_sce_catalogue.sql is shared
-- reference material: every authenticated user reads the same 183 rows, so
-- editing one in place would rewrite it for everybody. Ownership splits the two
-- cases:
--
--   created_by IS NULL  -> shared, read-only, but may still be favourited
--   created_by = you     -> yours, fully editable and deletable
--
-- Ownership is stamped from the request JWT by trigger rather than accepted from
-- the client, so a caller cannot forge authorship by sending created_by.
--
-- Renames deliberately do NOT cascade. sce_blocks stores a denormalised
-- snapshot (source_catalogue_name / source_category, see
-- 20260930_add_block_catalogue_provenance.sql) so a block keeps the name it was
-- placed with. Editing a catalogue row therefore never rewrites history in
-- Story Mix, and no bulk block update is needed on save.

ALTER TABLE sce_catalogue_entries
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_sce_catalogue_entries_created_by ON sce_catalogue_entries(created_by);

-- Stamp authorship from the JWT. BEFORE INSERT/UPDATE so RLS WITH CHECK sees
-- the final value.
CREATE OR REPLACE FUNCTION sce_catalogue_stamp_owner() RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := auth.uid();
  END IF;
  NEW.updated_by := auth.uid();
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sce_catalogue_stamp_owner ON sce_catalogue_entries;
CREATE TRIGGER trg_sce_catalogue_stamp_owner
  BEFORE INSERT OR UPDATE ON sce_catalogue_entries
  FOR EACH ROW EXECUTE FUNCTION sce_catalogue_stamp_owner();

-- Shared rows stay read-only apart from the favourite toggle. The permissive
-- policy below lets the UPDATE reach the trigger; this is what rejects it, so
-- the caller gets a real error instead of a silently skipped row.
CREATE OR REPLACE FUNCTION sce_catalogue_guard_shared() RETURNS TRIGGER AS $$
BEGIN
  IF OLD.created_by IS NULL THEN
    IF NEW.name IS DISTINCT FROM OLD.name
       OR NEW.category IS DISTINCT FROM OLD.category
       OR NEW.purpose IS DISTINCT FROM OLD.purpose
       OR NEW.prompt_questions IS DISTINCT FROM OLD.prompt_questions
       OR NEW.default_color IS DISTINCT FROM OLD.default_color
       OR NEW.active IS DISTINCT FROM OLD.active THEN
      RAISE EXCEPTION
        'This catalogue entry is shared and read-only. Duplicate it to make an editable copy.'
        USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sce_catalogue_guard_shared ON sce_catalogue_entries;
CREATE TRIGGER trg_sce_catalogue_guard_shared
  BEFORE UPDATE ON sce_catalogue_entries
  FOR EACH ROW EXECUTE FUNCTION sce_catalogue_guard_shared();

-- Replace the all-or-nothing policy with a read/write split.
--
-- Order matters. Permissive policies are OR'd together, so the old blanket
-- policy and the new ones can coexist: creating them first means the table is
-- never left in a window where it has no write policy at all. The blanket policy
-- is dropped LAST, and that single statement is the moment the restriction
-- starts applying. Dropping it first would break even the favourite toggle if
-- the rest of the script failed.
--
-- Each new policy is dropped IF EXISTS first so re-running the migration is
-- safe; without that, the second run aborts on the first CREATE POLICY.
DROP POLICY IF EXISTS "Read catalogue" ON sce_catalogue_entries;
DROP POLICY IF EXISTS "Create own catalogue" ON sce_catalogue_entries;
DROP POLICY IF EXISTS "Edit own catalogue" ON sce_catalogue_entries;
DROP POLICY IF EXISTS "Favourite shared catalogue" ON sce_catalogue_entries;
DROP POLICY IF EXISTS "Delete own catalogue" ON sce_catalogue_entries;

CREATE POLICY "Read catalogue" ON sce_catalogue_entries
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Create own catalogue" ON sce_catalogue_entries
  FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "Edit own catalogue" ON sce_catalogue_entries
  FOR UPDATE
  USING (created_by = auth.uid())
  WITH CHECK (created_by = auth.uid());

-- Shared rows are reachable by UPDATE so the favourite toggle still works; the
-- guard trigger is what keeps their content frozen.
CREATE POLICY "Favourite shared catalogue" ON sce_catalogue_entries
  FOR UPDATE
  USING (created_by IS NULL)
  WITH CHECK (created_by IS NULL);

CREATE POLICY "Delete own catalogue" ON sce_catalogue_entries
  FOR DELETE USING (created_by = auth.uid());

-- The restrictive policies are in place; remove the blanket grant last.
DROP POLICY IF EXISTS "Authenticated full access" ON sce_catalogue_entries;