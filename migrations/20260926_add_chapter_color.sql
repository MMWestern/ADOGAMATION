-- Add color column to sce_chapters

ALTER TABLE sce_chapters ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#3b82f6';
