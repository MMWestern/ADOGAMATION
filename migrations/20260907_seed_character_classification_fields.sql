-- Codex v2.3 Phase 1: Seed character/creature classification entity_link fields
-- Links Characters and Creatures to Species, Culture, Family, Organisation, System
-- Date: 2026-09-07

-- Character classification fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('character', 'species', 'Species', 'entity_link', 'Classification', 10, 'Biological/metaphysical type (e.g. Human, Elf, Werewolf)', '{"entity_type_key":"species"}'),
  ('character', 'culture', 'Culture', 'entity_link', 'Classification', 20, 'Cultural identity (e.g. Northern Terran, Fen Tribes)', '{"entity_type_key":"culture"}'),
  ('character', 'family', 'Family / House / Clan', 'entity_link', 'Classification', 30, 'Lineage or social group (e.g. House Kelth, Black-Reed Clan)', '{"entity_type_key":"family"}'),
  ('character', 'profession', 'Profession / Occupation', 'text', 'Classification', 40, 'What they do (e.g. Space Surgeon, Detective, Farmer)', NULL),
  ('character', 'background', 'Background / Origin', 'text', 'Classification', 50, 'Formative origin (e.g. Noble, Ex-Soldier, Colonial Academy)', NULL),
  ('character', 'organisation', 'Organisation / Faction', 'entity_link', 'Classification', 60, 'Institutional affiliation (e.g. Guild, Galactic Medical Corps)', '{"entity_type_key":"organisation"}'),
  ('character', 'progression_system', 'Progression System', 'entity_link', 'Classification', 70, 'Ruleset governing progression (e.g. Uni-Verse)', '{"entity_type_key":"system_rule"}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Creature classification fields (same Species link)
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('creature', 'species', 'Species', 'entity_link', 'Classification', 10, 'Biological type (e.g. Dire Wolf, Marsh Troll)', '{"entity_type_key":"species"}'),
  ('creature', 'culture', 'Culture', 'entity_link', 'Classification', 20, 'Cultural identity if applicable', '{"entity_type_key":"culture"}'),
  ('creature', 'family', 'Family / Pack / Clan', 'entity_link', 'Classification', 30, 'Social group if applicable', '{"entity_type_key":"family"}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Add "applies_to" relationship type for Starting Pack associations
INSERT INTO codex_relationship_types (key, forward_label, inverse_label, is_directional, description) VALUES
  ('applies_to', 'Applies to', 'Has pack', TRUE, 'Links a starting pack to a classification it applies to (e.g. Human Baseline applies to Human Species)')
ON CONFLICT (key) DO NOTHING;
