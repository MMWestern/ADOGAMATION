-- Add category and crop_data columns to image_assets
-- Category: single classification per image
-- crop_data: JSON object storing crop coordinates and cropped variant path

ALTER TABLE image_assets
  ADD COLUMN IF NOT EXISTS category text DEFAULT 'general',
  ADD COLUMN IF NOT EXISTS crop_data jsonb DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_image_assets_category ON image_assets(category);

-- Backfill existing images as 'general'
UPDATE image_assets SET category = 'general' WHERE category IS NULL;
