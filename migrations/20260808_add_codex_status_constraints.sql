-- Stage 1C: Add CHECK constraints for codex entity status fields
-- World Builder implementation plan
--
-- IMPORTANT: Verify existing data complies before running this migration.
-- Query to check:
--   SELECT DISTINCT status FROM codex_entities;
--   SELECT DISTINCT canon_status FROM codex_entities;
--   SELECT DISTINCT visibility FROM codex_entities;
--   SELECT DISTINCT spoiler_level FROM codex_entities;
--
-- If any values don't match the allowed list, update them first.

-- Status field
ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_status;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_status
  CHECK (status IN ('draft', 'active', 'archived'));

-- Canon status field
ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_canon_status;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_canon_status
  CHECK (canon_status IN ('draft', 'provisional', 'canon', 'deprecated'));

-- Visibility field
ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_visibility;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_visibility
  CHECK (visibility IN ('private', 'author_only', 'public'));

-- Spoiler level field
ALTER TABLE codex_entities DROP CONSTRAINT IF EXISTS chk_codex_spoiler;
ALTER TABLE codex_entities ADD CONSTRAINT chk_codex_spoiler
  CHECK (spoiler_level IN ('none', 'mild', 'major', 'secret'));
