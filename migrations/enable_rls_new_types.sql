-- Migration: Enable RLS on new codex type tables
-- Date: 2026-06-03
-- Run this in Supabase SQL Editor after add_new_codex_types.sql

-- ============================================
-- TABLES
-- ============================================

ALTER TABLE series_objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_object_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_object_character_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_object_location_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_object_lore_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_lore ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_lore_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_subplots ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_subplot_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_other ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_other_books ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLICIES
-- ============================================

CREATE POLICY "Authenticated full access" ON series_objects
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_object_books
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_object_character_links
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_object_location_links
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_object_lore_links
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_lore
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_lore_books
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_subplots
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_subplot_books
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_other
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_other_books
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
