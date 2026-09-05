-- Phase 1.7: Seed initial field definitions for common entity types
-- These define the schema-driven fields that will render in the UI
-- Date: 2026-09-05

-- Character fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('character', 'age', 'Age', 'text', 'Identity', 10, 'Character age or age range'),
  ('character', 'gender', 'Gender', 'text', 'Identity', 20, 'Gender identity'),
  ('character', 'height', 'Height', 'text', 'Physical', 30, 'Physical height'),
  ('character', 'build', 'Build', 'text', 'Physical', 40, 'Body type/build'),
  ('character', 'hair', 'Hair', 'text', 'Physical', 50, 'Hair color/style'),
  ('character', 'eyes', 'Eyes', 'text', 'Physical', 60, 'Eye color'),
  ('character', 'notable_features', 'Notable Features', 'long_text', 'Physical', 70, 'Distinctive physical features'),
  ('character', 'personality_traits', 'Personality Traits', 'long_text', 'Personality', 80, 'Key personality characteristics'),
  ('character', 'speech_patterns', 'Speech Patterns', 'long_text', 'Personality', 90, 'How the character speaks'),
  ('character', 'fears', 'Fears', 'long_text', 'Psychology', 100, 'What the character fears'),
  ('character', 'desires', 'Desires', 'long_text', 'Psychology', 110, 'What the character wants'),
  ('character', 'secrets', 'Secrets', 'long_text', 'Psychology', 120, 'What the character hides')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Location fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('location', 'climate', 'Climate', 'text', 'Geography', 10, 'Climate/weather patterns'),
  ('location', 'terrain', 'Terrain', 'text', 'Geography', 20, 'Land type/terrain'),
  ('location', 'population', 'Population', 'text', 'Demographics', 30, 'Population size/type'),
  ('location', 'government', 'Government', 'text', 'Politics', 40, 'Local government type'),
  ('location', 'notable_landmarks', 'Notable Landmarks', 'long_text', 'Features', 50, 'Key landmarks and features'),
  ('location', 'resources', 'Resources', 'long_text', 'Economy', 60, 'Natural resources/trade goods')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Organisation fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('organisation', 'org_type', 'Type', 'select', 'Identity', 10, 'Organisation type', '{"options":["Guild","Faction","Government","Military","Religious","Criminal","Academic","Commercial","Other"]}'),
  ('organisation', 'founded', 'Founded', 'text', 'History', 20, 'When/how it was founded', NULL),
  ('organisation', 'headquarters', 'Headquarters', 'text', 'Structure', 30, 'Main base of operations', NULL),
  ('organisation', 'membership_size', 'Membership Size', 'text', 'Structure', 40, 'Number of members', NULL),
  ('organisation', 'goals', 'Goals', 'long_text', 'Motivation', 50, 'Primary objectives', NULL),
  ('organisation', 'resources', 'Resources', 'long_text', 'Power', 60, 'Available resources/power', NULL)
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Item fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('item', 'material', 'Material', 'text', 'Physical', 10, 'Primary material(s)', NULL),
  ('item', 'weight', 'Weight', 'text', 'Physical', 20, 'Weight/mass', NULL),
  ('item', 'dimensions', 'Dimensions', 'text', 'Physical', 30, 'Size/shape', NULL),
  ('item', 'rarity', 'Rarity', 'select', 'Properties', 40, 'How rare this item is', '{"options":["Common","Uncommon","Rare","Epic","Legendary","Unique"]}'),
  ('item', 'powers', 'Powers/Abilities', 'long_text', 'Magical', 50, 'Magical properties or abilities', NULL),
  ('item', 'history', 'Item History', 'long_text', 'Lore', 60, 'Origin and history of the item', NULL)
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Magic System fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('magic_system', 'source', 'Source', 'text', 'Fundamentals', 10, 'Where magic comes from'),
  ('magic_system', 'cost', 'Cost/Limitation', 'long_text', 'Fundamentals', 20, 'What using magic costs'),
  ('magic_system', 'rules', 'Rules', 'long_text', 'Mechanics', 30, 'Core rules of the system'),
  ('magic_system', 'training', 'Training', 'long_text', 'Mechanics', 40, 'How magic is learned/trained'),
  ('magic_system', 'types', 'Types/Categories', 'long_text', 'Classification', 50, 'Different types of magic'),
  ('magic_system', 'artifacts', 'Notable Artifacts', 'long_text', 'Related', 60, 'Important magical items')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Species fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('species', 'lifespan', 'Lifespan', 'text', 'Biology', 10, 'Typical lifespan'),
  ('species', 'habitat', 'Habitat', 'text', 'Biology', 20, 'Natural habitat/environment'),
  ('species', 'physical_traits', 'Physical Traits', 'long_text', 'Biology', 30, 'Distinctive physical characteristics'),
  ('species', 'culture', 'Culture', 'long_text', 'Society', 40, 'Cultural practices and norms'),
  ('species', 'abilities', 'Abilities', 'long_text', 'Powers', 50, 'Innate abilities or powers'),
  ('species', 'weaknesses', 'Weaknesses', 'long_text', 'Powers', 60, 'Known weaknesses')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Religion fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('religion', 'deity', 'Deity/Deities', 'text', 'Core', 10, 'Primary deity or deities'),
  ('religion', 'tenets', 'Core Tenets', 'long_text', 'Beliefs', 20, 'Fundamental beliefs and rules'),
  ('religion', 'worship', 'Worship Practices', 'long_text', 'Practices', 30, 'How worship is conducted'),
  ('religion', 'structure', 'Organisation Structure', 'long_text', 'Structure', 40, 'Religious hierarchy and organization'),
  ('religion', 'artifacts', 'Sacred Artifacts', 'long_text', 'Related', 50, 'Important religious items'),
  ('religion', 'holidays', 'Holy Days', 'long_text', 'Calendar', 60, 'Important religious dates/events')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Government fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('government', 'gov_type', 'Government Type', 'text', 'Structure', 10, 'Type of government'),
  ('government', 'leader', 'Current Leader', 'text', 'Leadership', 20, 'Current head of state'),
  ('government', 'laws', 'Key Laws', 'long_text', 'Legal', 30, 'Important laws and regulations'),
  ('government', 'military', 'Military', 'long_text', 'Power', 40, 'Military forces and capabilities'),
  ('government', 'economy', 'Economic System', 'long_text', 'Economy', 50, 'Economic structure and trade'),
  ('government', 'diplomacy', 'Foreign Relations', 'long_text', 'Diplomacy', 60, 'Relations with other governments')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Creature fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('creature', 'habitat', 'Habitat', 'text', 'Biology', 10, 'Natural habitat'),
  ('creature', 'diet', 'Diet', 'text', 'Biology', 20, 'What it eats'),
  ('creature', 'behavior', 'Behavior', 'long_text', 'Biology', 30, 'Typical behavior patterns'),
  ('creature', 'abilities', 'Abilities', 'long_text', 'Powers', 40, 'Special abilities'),
  ('creature', 'weaknesses', 'Weaknesses', 'long_text', 'Powers', 50, 'Known weaknesses'),
  ('creature', 'domestication', 'Domestication', 'long_text', 'Interaction', 60, 'Can it be tamed/domesticated?')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Quest fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text) VALUES
  ('quest', 'quest_giver', 'Quest Giver', 'text', 'Details', 10, 'Who gives this quest'),
  ('quest', 'objective', 'Objective', 'long_text', 'Details', 20, 'What needs to be done'),
  ('quest', 'reward', 'Reward', 'long_text', 'Details', 30, 'What the reward is'),
  ('quest', 'deadline', 'Deadline', 'text', 'Constraints', 40, 'Time constraints'),
  ('quest', 'obstacles', 'Obstacles', 'long_text', 'Challenges', 50, 'What stands in the way'),
  ('quest', 'consequences', 'Consequences', 'long_text', 'Impact', 60, 'What happens if failed/completed')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Lore fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('lore', 'era', 'Era/Time Period', 'text', 'Context', 10, 'When this lore is from', NULL),
  ('lore', 'source', 'Source', 'text', 'Context', 20, 'Where this knowledge comes from', NULL),
  ('lore', 'reliability', 'Reliability', 'select', 'Context', 30, 'How reliable this information is', '{"options":["Verified","Likely","Rumored","Disputed","Unknown"]}'),
  ('lore', 'related_events', 'Related Events', 'long_text', 'Connections', 40, 'Related historical events', NULL),
  ('lore', 'impact', 'Impact', 'long_text', 'Significance', 50, 'Why this lore matters', NULL)
ON CONFLICT (entity_type_key, field_key) DO NOTHING;

-- Story Thread fields
INSERT INTO codex_entity_field_definitions (entity_type_key, field_key, label, field_type, group_name, sort_order, help_text, options_json) VALUES
  ('story_thread', 'thread_type', 'Thread Type', 'select', 'Classification', 10, 'Type of story thread', '{"options":["Main Plot","Subplot","Side Story","Flashback","Foreshadowing","Other"]}'),
  ('story_thread', 'tension', 'Tension Level', 'select', 'Dynamics', 20, 'Current tension level', '{"options":["Low","Medium","High","Critical"]}'),
  ('story_thread', 'resolution', 'Resolution Status', 'select', 'Dynamics', 30, 'Whether resolved', '{"options":["Unresolved","In Progress","Resolved","Abandoned"]}')
ON CONFLICT (entity_type_key, field_key) DO NOTHING;
