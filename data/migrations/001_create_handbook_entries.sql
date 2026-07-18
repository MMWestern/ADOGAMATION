-- Create handbook_entries table for Adogamation HQ Handbook module
-- Run this in your Supabase SQL editor

CREATE TABLE IF NOT EXISTS handbook_entries (
  id TEXT PRIMARY KEY,
  doc_id TEXT UNIQUE,
  title TEXT NOT NULL,
  department TEXT NOT NULL,
  section TEXT NOT NULL,
  entry_type TEXT NOT NULL DEFAULT 'Reference',
  status TEXT NOT NULL DEFAULT 'draft',
  content TEXT DEFAULT '',
  tags JSONB DEFAULT '[]',
  related_entries JSONB DEFAULT '[]',
  version INTEGER DEFAULT 1,
  author TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_handbook_entries_doc_id ON handbook_entries (doc_id);

-- Enable Row Level Security
ALTER TABLE handbook_entries ENABLE ROW LEVEL SECURITY;

-- Create policy for authenticated users to read all entries
CREATE POLICY "Authenticated users can read handbook entries"
  ON handbook_entries
  FOR SELECT
  TO authenticated
  USING (true);

-- Create policy for authenticated users to insert entries
CREATE POLICY "Authenticated users can insert handbook entries"
  ON handbook_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Create policy for authenticated users to update entries
CREATE POLICY "Authenticated users can update handbook entries"
  ON handbook_entries
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create policy for authenticated users to delete entries
CREATE POLICY "Authenticated users can delete handbook entries"
  ON handbook_entries
  FOR DELETE
  TO authenticated
  USING (true);

-- Create index for common queries
CREATE INDEX IF NOT EXISTS idx_handbook_entries_department ON handbook_entries (department);
CREATE INDEX IF NOT EXISTS idx_handbook_entries_section ON handbook_entries (section);
CREATE INDEX IF NOT EXISTS idx_handbook_entries_updated_at ON handbook_entries (updated_at DESC);
