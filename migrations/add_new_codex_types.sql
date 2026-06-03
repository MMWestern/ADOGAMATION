-- Migration: Add Objects, Lore, Subplots, Other codex types
-- Date: 2026-06-03
-- Run this in Supabase SQL Editor

-- ============================================
-- OBJECTS (mirrors series_locations structure)
-- ============================================

CREATE TABLE IF NOT EXISTS series_objects (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL DEFAULT '',
  image_url TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  significance TEXT NOT NULL DEFAULT '',
  notable_events TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  color VARCHAR(7) NOT NULL DEFAULT '',
  scope TEXT NOT NULL DEFAULT 'book',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_series_objects_series ON series_objects(series_id);

CREATE TABLE IF NOT EXISTS series_object_books (
  id BIGSERIAL PRIMARY KEY,
  object_id BIGINT NOT NULL REFERENCES series_objects(id) ON DELETE CASCADE,
  project_id BIGINT NOT NULL,
  notes TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_series_object_books_object ON series_object_books(object_id);

CREATE TABLE IF NOT EXISTS series_object_character_links (
  id BIGSERIAL PRIMARY KEY,
  object_id BIGINT NOT NULL REFERENCES series_objects(id) ON DELETE CASCADE,
  character_id BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_series_object_char_links ON series_object_character_links(object_id);

CREATE TABLE IF NOT EXISTS series_object_location_links (
  id BIGSERIAL PRIMARY KEY,
  object_id BIGINT NOT NULL REFERENCES series_objects(id) ON DELETE CASCADE,
  location_id BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_series_object_loc_links ON series_object_location_links(object_id);

CREATE TABLE IF NOT EXISTS series_object_lore_links (
  id BIGSERIAL PRIMARY KEY,
  object_id BIGINT NOT NULL REFERENCES series_objects(id) ON DELETE CASCADE,
  lore_id BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_series_object_lore_links ON series_object_lore_links(object_id);

-- ============================================
-- LORE (multiple entries per series)
-- ============================================

CREATE TABLE IF NOT EXISTS series_lore (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  image_url TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  color VARCHAR(7) NOT NULL DEFAULT '',
  scope TEXT NOT NULL DEFAULT 'series',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_series_lore_series ON series_lore(series_id);

CREATE TABLE IF NOT EXISTS series_lore_books (
  id BIGSERIAL PRIMARY KEY,
  lore_id BIGINT NOT NULL REFERENCES series_lore(id) ON DELETE CASCADE,
  project_id BIGINT NOT NULL,
  notes TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_series_lore_books_lore ON series_lore_books(lore_id);

-- ============================================
-- SUBPLOTS
-- ============================================

CREATE TABLE IF NOT EXISTS series_subplots (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  image_url TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  color VARCHAR(7) NOT NULL DEFAULT '',
  scope TEXT NOT NULL DEFAULT 'book',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_series_subplots_series ON series_subplots(series_id);

CREATE TABLE IF NOT EXISTS series_subplot_books (
  id BIGSERIAL PRIMARY KEY,
  subplot_id BIGINT NOT NULL REFERENCES series_subplots(id) ON DELETE CASCADE,
  project_id BIGINT NOT NULL,
  notes TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_series_subplot_books_subplot ON series_subplot_books(subplot_id);

-- ============================================
-- OTHER
-- ============================================

CREATE TABLE IF NOT EXISTS series_other (
  id BIGSERIAL PRIMARY KEY,
  series_id BIGINT NOT NULL REFERENCES series(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT '',
  image_url TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0,
  color VARCHAR(7) NOT NULL DEFAULT '',
  scope TEXT NOT NULL DEFAULT 'book',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_series_other_series ON series_other(series_id);

CREATE TABLE IF NOT EXISTS series_other_books (
  id BIGSERIAL PRIMARY KEY,
  other_id BIGINT NOT NULL REFERENCES series_other(id) ON DELETE CASCADE,
  project_id BIGINT NOT NULL,
  notes TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_series_other_books_other ON series_other_books(other_id);
