-- Series Doc URLs: Migrate legacy_doc_urls JSONB to documents table
-- Run in Supabase SQL editor
-- Reads series.legacy_doc_urls and upserts into documents table

INSERT INTO documents (series_id, doc_type, title, markdown_content, word_count)
SELECT
  s.id AS series_id,
  kv.doc_type,
  kv.doc_type AS title,
  kv.url AS markdown_content,
  0 AS word_count
FROM series s,
LATERAL jsonb_each_text(COALESCE(s.legacy_doc_urls, '{}'::jsonb)) AS kv(doc_type, url)
WHERE kv.url IS NOT NULL AND kv.url != ''
ON CONFLICT DO NOTHING;
