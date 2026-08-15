-- Series Metadata Inheritance: Copy project genre/pen_name/format to their series
-- Run AFTER adding columns to series table (20260815_add_series_metadata_columns.sql)
-- Uses the first project in each series as the source of truth

UPDATE series s
SET
  genre = sub.genre,
  pen_name = sub.pen_name,
  format = sub.format
FROM (
  SELECT DISTINCT ON (series_id)
    series_id,
    genre,
    pen_name,
    format
  FROM projects
  WHERE series_id IS NOT NULL
    AND (genre IS NOT NULL OR pen_name IS NOT NULL OR format IS NOT NULL)
  ORDER BY series_id, id
) sub
WHERE s.id = sub.series_id
  AND s.genre IS NULL
  AND s.pen_name IS NULL
  AND s.format IS NULL;
