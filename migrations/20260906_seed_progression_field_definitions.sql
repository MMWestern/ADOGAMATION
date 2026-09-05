-- Codex v2.1 Phase 1: Seed progression field definitions
-- Adds schema-driven fields for stat, resource, skill_ability, class_path, trait_perk
-- Date: 2026-09-06

-- Stat fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('stat', 'abbreviation', 'Abbreviation', 'text', 'Identity', 10, 'Short form: STR, DEX, INT, etc.', NULL),
  ('stat', 'category', 'Category', 'select', 'Identity', 20, 'Stat category', '{"options":["Physical","Mental","Social","Magical","Derived","Other"]}'),
  ('stat', 'value_type', 'Value Type', 'select', 'Identity', 30, 'How the value is represented', '{"options":["integer","decimal","percentage","boolean","text","rank","enum","calculated"]}'),
  ('stat', 'default_value', 'Default Value', 'text', 'Defaults', 40, 'Default/start value', NULL),
  ('stat', 'min_value', 'Minimum Value', 'number', 'Bounds', 50, 'Optional lower bound', NULL),
  ('stat', 'max_value', 'Maximum Value', 'number', 'Bounds', 60, 'Optional upper bound', NULL),
  ('stat', 'stat_kind', 'Stat Kind', 'select', 'Classification', 70, 'Base or derived stat', '{"options":["base","derived"]}'),
  ('stat', 'formula', 'Formula', 'long_text', 'Derived', 80, 'Human-readable calculation (e.g. STR × 5)', NULL),
  ('stat', 'progression_method', 'Progression Method', 'long_text', 'Rules', 90, 'How the stat normally changes', NULL),
  ('stat', 'display_order', 'Display Order', 'number', 'Display', 100, 'Ordering on character sheets', NULL),
  ('stat', 'player_visible', 'Player Visible', 'boolean', 'Display', 110, 'Whether visible in-world', NULL),
  ('stat', 'description_rules', 'Description / Rules', 'long_text', 'Documentation', 120, 'Mechanical meaning of this stat', NULL),
  ('stat', 'system', 'System', 'entity_link', 'Links', 130, 'Parent system definition', '{"entity_type_key":"system_rule"}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Resource fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('resource', 'abbreviation', 'Abbreviation', 'text', 'Identity', 10, 'Short form: HP, MP, XP, etc.', NULL),
  ('resource', 'category', 'Category', 'select', 'Identity', 20, 'Resource category', '{"options":["Health","Mana","Stamina","Experience","Energy","Currency","Other"]}'),
  ('resource', 'value_type', 'Value Type', 'select', 'Identity', 30, 'How the value is represented', '{"options":["integer","decimal","percentage"]}'),
  ('resource', 'default_value', 'Default Value', 'number', 'Defaults', 40, 'Default/start value', NULL),
  ('resource', 'min_value', 'Minimum Value', 'number', 'Bounds', 50, 'Lower bound (usually 0)', NULL),
  ('resource', 'max_value', 'Maximum Value', 'number', 'Bounds', 60, 'Upper bound', NULL),
  ('resource', 'max_formula', 'Maximum Formula', 'long_text', 'Rules', 70, 'How max is calculated (e.g. CON × 10)', NULL),
  ('resource', 'regeneration_rule', 'Regeneration Rule', 'long_text', 'Rules', 80, 'How the resource regenerates', NULL),
  ('resource', 'depletion_rule', 'Depletion Rule', 'long_text', 'Rules', 90, 'What happens at zero', NULL),
  ('resource', 'can_exceed_max', 'Can Exceed Maximum', 'boolean', 'Rules', 100, 'Whether overcharge is possible', NULL),
  ('resource', 'player_visible', 'Player Visible', 'boolean', 'Display', 110, 'Whether visible in-world', NULL),
  ('resource', 'display_order', 'Display Order', 'number', 'Display', 120, 'Ordering on character sheets', NULL),
  ('resource', 'system', 'System', 'entity_link', 'Links', 130, 'Parent system definition', '{"entity_type_key":"system_rule"}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Skill/Ability fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('skill_ability', 'skill_type', 'Skill Type', 'select', 'Classification', 10, 'Type of skill', '{"options":["Spell","Ability","Technique","Passive","Craft","Social","Other"]}'),
  ('skill_ability', 'rank_type', 'Rank Type', 'select', 'Classification', 20, 'How ranks are represented', '{"options":["numeric","tier","named","boolean"]}'),
  ('skill_ability', 'min_rank', 'Minimum Rank', 'text', 'Bounds', 30, 'Starting rank', NULL),
  ('skill_ability', 'max_rank', 'Maximum Rank', 'text', 'Bounds', 40, 'Maximum achievable rank', NULL),
  ('skill_ability', 'governing_stat', 'Governing Stat', 'entity_link', 'Mechanics', 50, 'Primary stat for this skill', '{"entity_type_key":"stat"}'),
  ('skill_ability', 'cost_resource', 'Cost Resource', 'entity_link', 'Mechanics', 60, 'Resource consumed on use', '{"entity_type_key":"resource"}'),
  ('skill_ability', 'cost', 'Cost', 'text', 'Mechanics', 70, 'Amount of resource consumed', NULL),
  ('skill_ability', 'cooldown', 'Cooldown', 'text', 'Mechanics', 80, 'Time between uses', NULL),
  ('skill_ability', 'progression_method', 'Progression Method', 'long_text', 'Rules', 90, 'How the skill improves', NULL),
  ('skill_ability', 'requirements', 'Requirements', 'long_text', 'Rules', 100, 'Prerequisites to learn/use', NULL),
  ('skill_ability', 'player_visible', 'Player Visible', 'boolean', 'Display', 110, 'Whether visible in-world', NULL),
  ('skill_ability', 'system', 'System', 'entity_link', 'Links', 120, 'Parent system definition', '{"entity_type_key":"system_rule"}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Class/Path fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('class_path', 'class_type', 'Class Type', 'select', 'Classification', 10, 'Type of class', '{"options":["Combat","Magic","Support","Hybrid","Crafting","Social","Other"]}'),
  ('class_path', 'tier', 'Tier', 'text', 'Progression', 20, 'Class tier/rank', NULL),
  ('class_path', 'min_level', 'Minimum Level', 'number', 'Requirements', 30, 'Level required to acquire', NULL),
  ('class_path', 'max_level', 'Maximum Level', 'number', 'Requirements', 40, 'Maximum level in this class', NULL),
  ('class_path', 'progression_method', 'Progression Method', 'long_text', 'Rules', 50, 'How class progression works', NULL),
  ('class_path', 'requirements', 'Requirements', 'long_text', 'Rules', 60, 'Prerequisites to acquire', NULL),
  ('class_path', 'player_visible', 'Player Visible', 'boolean', 'Display', 70, 'Whether visible in-world', NULL),
  ('class_path', 'system', 'System', 'entity_link', 'Links', 80, 'Parent system definition', '{"entity_type_key":"system_rule"}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Trait/Perk fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('trait_perk', 'trait_type', 'Trait Type', 'select', 'Classification', 10, 'Type of trait', '{"options":["Racial","Class","Background","Achievement","Item","Quest","Other"]}'),
  ('trait_perk', 'rank_type', 'Rank Type', 'select', 'Classification', 20, 'How ranks are represented', '{"options":["numeric","tier","named","boolean"]}'),
  ('trait_perk', 'max_rank', 'Maximum Rank', 'text', 'Bounds', 30, 'Maximum achievable rank', NULL),
  ('trait_perk', 'stackable', 'Stackable', 'boolean', 'Rules', 40, 'Whether multiple instances stack', NULL),
  ('trait_perk', 'effect', 'Effect', 'long_text', 'Rules', 50, 'What the trait does', NULL),
  ('trait_perk', 'requirements', 'Requirements', 'long_text', 'Rules', 60, 'Prerequisites to acquire', NULL),
  ('trait_perk', 'player_visible', 'Player Visible', 'boolean', 'Display', 70, 'Whether visible in-world', NULL),
  ('trait_perk', 'system', 'System', 'entity_link', 'Links', 80, 'Parent system definition', '{"entity_type_key":"system_rule"}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;
