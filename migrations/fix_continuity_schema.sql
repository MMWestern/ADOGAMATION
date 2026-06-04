-- Migration: Fix continuity schema — ensure link tables and scope/sort_order/color exist
-- Date: 2026-06-04
-- Run this in Supabase SQL Editor

-- Add columns that may be missing from series_continuity_entries
ALTER TABLE series_continuity_entries
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

ALTER TABLE series_continuity_entries
  ADD COLUMN IF NOT EXISTS scope TEXT NOT NULL DEFAULT 'book';

ALTER TABLE series_continuity_entries
  ADD COLUMN IF NOT EXISTS color VARCHAR(7) NOT NULL DEFAULT '';

-- Ensure link tables exist (these are needed for book/project assignment, character linking, location linking)
CREATE TABLE IF NOT EXISTS series_continuity_character_links (
  id BIGSERIAL PRIMARY KEY,
  continuity_entry_id BIGINT NOT NULL REFERENCES series_continuity_entries(id) ON DELETE CASCADE,
  character_id BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cont_char_links_entry ON series_continuity_character_links(continuity_entry_id);

CREATE TABLE IF NOT EXISTS series_continuity_location_links (
  id BIGSERIAL PRIMARY KEY,
  continuity_entry_id BIGINT NOT NULL REFERENCES series_continuity_entries(id) ON DELETE CASCADE,
  location_id BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cont_loc_links_entry ON series_continuity_location_links(continuity_entry_id);

CREATE TABLE IF NOT EXISTS series_continuity_project_links (
  id BIGSERIAL PRIMARY KEY,
  continuity_entry_id BIGINT NOT NULL REFERENCES series_continuity_entries(id) ON DELETE CASCADE,
  project_id BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cont_proj_links_entry ON series_continuity_project_links(continuity_entry_id);

-- Enable RLS on link tables and add policies (safe to re-run)
ALTER TABLE series_continuity_character_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_continuity_location_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_continuity_project_links ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'series_continuity_character_links' AND policyname = 'Authenticated full access') THEN
    CREATE POLICY "Authenticated full access" ON series_continuity_character_links
      FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'series_continuity_location_links' AND policyname = 'Authenticated full access') THEN
    CREATE POLICY "Authenticated full access" ON series_continuity_location_links
      FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'series_continuity_project_links' AND policyname = 'Authenticated full access') THEN
    CREATE POLICY "Authenticated full access" ON series_continuity_project_links
      FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
  END IF;
END $$;
