-- Migration: Add world-building entity types (map, magic_system)
-- Date: 2026-06-07
-- Phase 2: World Building Workspace

INSERT INTO codex_entity_types (key, name_singular, name_plural, icon, description, is_system_type, sort_order) VALUES
  ('map', 'Map', 'Maps', 'map', 'Geographic maps, region layouts, spatial references', FALSE, 55),
  ('magic_system', 'Magic System', 'Magic Systems', 'zap', 'Magical rules, systems, powers, and limitations', FALSE, 65)
ON CONFLICT (key) DO NOTHING;
