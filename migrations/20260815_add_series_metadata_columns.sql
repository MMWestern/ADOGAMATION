-- Series Metadata Inheritance: Add genre, pen_name, format columns to series table
-- Run in Supabase SQL editor

ALTER TABLE series ADD COLUMN IF NOT EXISTS genre TEXT;
ALTER TABLE series ADD COLUMN IF NOT EXISTS pen_name TEXT;
ALTER TABLE series ADD COLUMN IF NOT EXISTS format TEXT;
