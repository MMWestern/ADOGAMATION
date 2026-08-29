-- Migration: Seed new entity types for codex format presets
-- Date: 2026-08-27
-- These types are used by the LitRPG, Standard Fantasy, and Contemporary presets

INSERT INTO codex_entity_types (key, name_singular, name_plural, icon, description, is_system_type, sort_order) VALUES
  -- Shared across multiple presets
  ('species', 'Species', 'Species', 'footprints', 'Races, species, or sentient creature types', FALSE, 100),
  ('creature', 'Creature', 'Creatures', 'dragon', 'Beasts, monsters, animals, and non-sentient entities', FALSE, 110),
  ('story_thread', 'Story Thread', 'Story Threads', 'thread', 'Plot threads, narrative arcs, and ongoing storylines', FALSE, 200),
  ('mystery', 'Mystery / Secret', 'Mysteries / Secrets', 'search', 'Unresolved questions, hidden truths, and secrets', FALSE, 210),
  ('foreshadowing', 'Foreshadowing', 'Foreshadowing', 'crystal-ball', 'Hints, clues, and foreshadowing elements', FALSE, 220),
  ('setup_payoff', 'Setup / Payoff', 'Setups / Payoffs', 'clapperboard', 'Planted elements and their eventual payoffs', FALSE, 230),
  ('easter_egg', 'Easter Egg', 'Easter Eggs', 'egg', 'Hidden references, homages, and Easter eggs', FALSE, 240),
  ('relationship', 'Relationship', 'Relationships', 'heart', 'Character relationships and dynamics', FALSE, 250),
  ('knowledge_state', 'Knowledge State', 'Knowledge States', 'brain', 'What characters know and when they learned it', FALSE, 260),
  ('document', 'Document', 'Documents', 'page-facing-up', 'In-world documents, letters, records', FALSE, 300),
  ('glossary', 'Glossary Entry', 'Glossary', 'book', 'Terminology, definitions, and notes', FALSE, 310),
  ('character_arc', 'Character Arc', 'Character Arcs', 'chart-increasing', 'Character growth trajectories and development arcs', FALSE, 205),
  -- LitRPG-specific
  ('power_system', 'Power System', 'Power Systems', 'high-voltage', 'Magical or game-like power systems and mechanics', FALSE, 120),
  ('class_path', 'Class / Path', 'Classes / Paths', 'shield', 'Character classes, paths, or specializations', FALSE, 130),
  ('stat', 'Stat', 'Stats', 'bar-chart', 'Attributes, stats, and numerical character properties', FALSE, 140),
  ('skill_ability', 'Skill / Ability', 'Skills / Abilities', 'sparkles', 'Learnable skills, abilities, and powers', FALSE, 150),
  ('trait_perk', 'Trait / Perk', 'Traits / Perks', 'bullseye', 'Innate traits, perks, and passive bonuses', FALSE, 160),
  ('resource', 'Resource', 'Resources', 'gem', 'Mana, stamina, energy, currencies, and other resources', FALSE, 170),
  ('system_rule', 'System Rule', 'System Rules', 'scroll', 'World system rules, mechanics, and constraints', FALSE, 180),
  ('progression', 'Progression', 'Progression', 'chart-increasing', 'Level-up paths, XP systems, and progression mechanics', FALSE, 400),
  ('character_build', 'Character Build', 'Character Builds', 'building-construction', 'Optimized character builds and loadouts', FALSE, 410),
  ('skill_tree', 'Skill Tree', 'Skill Trees', 'deciduous-tree', 'Skill trees, talent grids, and ability networks', FALSE, 420),
  ('evolution', 'Evolution', 'Evolution', 'butterfly', 'Class evolutions, transformations, and ascensions', FALSE, 430),
  ('progression_event', 'Progression Event', 'Progression Events', 'party-popper', 'Level-up events, milestones, and breakthroughs', FALSE, 440),
  ('equipment', 'Equipment', 'Equipment', 'crossed-swords', 'Wearable and wieldable equipment', FALSE, 500),
  ('inventory', 'Inventory', 'Inventory', 'school-backpack', 'Inventory management and storage', FALSE, 510),
  ('crafting', 'Crafting', 'Crafting', 'hammer-and-pick', 'Crafting recipes, materials, and processes', FALSE, 520),
  ('economy', 'Economy', 'Economy', 'coin', 'Trade, currency, shops, and economic systems', FALSE, 530),
  ('achievement', 'Achievement / Title', 'Achievements / Titles', 'trophy', 'Achievements, titles, and accomplishments', FALSE, 600),
  ('reward', 'Reward / Loot', 'Rewards / Loot', 'wrapped-gift', 'Quest rewards, loot tables, and treasure', FALSE, 610),
  -- Standard Fantasy-specific
  ('religion', 'Religion', 'Religions', 'place-of-worship', 'Religions, deities, faiths, and religious orders', FALSE, 125),
  ('government', 'Government', 'Governments', 'classical-building', 'Governments, political systems, and law', FALSE, 135),
  ('language', 'Language', 'Languages', 'speech-balloon', 'Languages, scripts, and communication systems', FALSE, 145),
  ('history_era', 'History / Era', 'History / Eras', 'closed-book', 'Historical periods, ages, and eras', FALSE, 155),
  ('realm_dimension', 'Realm / Dimension', 'Realms / Dimensions', 'globe-with-meridians', 'Planes of existence, dimensions, and realms', FALSE, 165),
  ('culture', 'Culture', 'Cultures', 'globe-showing-Europe-Africa', 'Cultures, customs, traditions, and societies', FALSE, 175),
  -- Contemporary-specific
  ('social_circle', 'Social Circle', 'Social Circles', 'handshake', 'Friend groups, social networks, and associations', FALSE, 255),
  ('romantic_arc', 'Romantic Arc', 'Romantic Arcs', 'sparkling-heart', 'Romance storylines and relationship development', FALSE, 215),
  ('secret', 'Secret', 'Secrets', 'locked', 'Character secrets, hidden truths, and lies', FALSE, 225),
  ('conflict', 'Conflict', 'Conflicts', 'collision', 'Interpersonal conflicts, rivalries, and tensions', FALSE, 235)
ON CONFLICT (key) DO NOTHING;
