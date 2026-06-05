-- Migration: Drop unused prototype tables (Phase 14)
-- Date: 2026-06-05
-- These tables have been fully replaced by the new generic codex engine
-- and are no longer queried when USE_NEW_CODEX_ENGINE is true.

DROP TABLE IF EXISTS series_objects CASCADE;
DROP TABLE IF EXISTS series_object_books CASCADE;
DROP TABLE IF EXISTS series_object_character_links CASCADE;
DROP TABLE IF EXISTS series_object_location_links CASCADE;
DROP TABLE IF EXISTS series_object_lore_links CASCADE;

DROP TABLE IF EXISTS series_lore CASCADE;
DROP TABLE IF EXISTS series_lore_books CASCADE;

DROP TABLE IF EXISTS series_subplots CASCADE;
DROP TABLE IF EXISTS series_subplot_books CASCADE;

DROP TABLE IF EXISTS series_other CASCADE;
DROP TABLE IF EXISTS series_other_books CASCADE;

DROP TABLE IF EXISTS series_characters CASCADE;
DROP TABLE IF EXISTS series_character_books CASCADE;
DROP TABLE IF EXISTS series_character_relationships CASCADE;

DROP TABLE IF EXISTS series_locations CASCADE;
DROP TABLE IF EXISTS series_location_books CASCADE;
