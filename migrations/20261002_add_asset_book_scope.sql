-- Story ideas can belong to a single book in a series, or stay shared.
-- book_id is nullable: NULL means the idea is shared across the whole series,
-- which is how every idea created before this migration is treated.
ALTER TABLE sce_assets
  ADD COLUMN IF NOT EXISTS book_id BIGINT REFERENCES projects(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_sce_assets_book ON sce_assets(book_id);
CREATE INDEX IF NOT EXISTS idx_sce_assets_series_book ON sce_assets(series_id, book_id);

COMMENT ON COLUMN sce_assets.book_id IS
  'Book this idea belongs to. NULL means shared across the series.';