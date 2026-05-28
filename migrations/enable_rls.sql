-- ADOGAMATION PRESS — Enable RLS on all tables
-- Run this in Supabase SQL Editor after enabling Auth
-- This creates a policy that requires authentication for all operations

-- ============================================
-- TABLES
-- ============================================

ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE series ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE image_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE general_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_characters ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_character_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_character_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_location_books ENABLE ROW LEVEL SECURITY;
ALTER TABLE series_continuity_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE book_creator_pockets ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLICIES — allow all operations for authenticated users
-- ============================================

CREATE POLICY "Authenticated full access" ON projects
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON documents
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON document_sections
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON image_assets
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON general_resources
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_characters
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_character_books
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_character_relationships
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_locations
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_location_books
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON series_continuity_entries
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated full access" ON book_creator_pockets
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- ============================================
-- STORAGE — allow authenticated uploads to project-images bucket
-- ============================================

CREATE POLICY "Authenticated storage access" ON storage.objects
  FOR ALL USING (
    bucket_id = 'project-images' AND auth.uid() IS NOT NULL
  ) WITH CHECK (
    bucket_id = 'project-images' AND auth.uid() IS NOT NULL
  );

CREATE POLICY "Authenticated bucket access" ON storage.buckets
  FOR ALL USING (
    id = 'project-images' AND auth.uid() IS NOT NULL
  ) WITH CHECK (
    id = 'project-images' AND auth.uid() IS NOT NULL
  );
