-- Migration: Create codex_format_presets table and seed built-in presets
-- Date: 2026-08-27

CREATE TABLE IF NOT EXISTS codex_format_presets (
  id BIGSERIAL PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  tree_definition JSONB NOT NULL DEFAULT '[]',
  is_builtin BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed built-in presets

-- LitRPG
INSERT INTO codex_format_presets (key, name, description, tree_definition, is_builtin, sort_order) VALUES
('litrpg', 'LitRPG', 'Game-like progression systems, stats, skills, equipment, and quests.',
'[
  {
    "category": "CORE",
    "items": [
      {"key":"characters","label":"Characters","icon":"\u{1F464}","entityTypeKey":"character"},
      {"key":"locations","label":"Locations","icon":"\u{1F4CD}","entityTypeKey":"location"},
      {"key":"organisations","label":"Organisations","icon":"\u{1F3E2}","entityTypeKey":"organisation"},
      {"key":"species","label":"Species","icon":"\u{1F43E}","entityTypeKey":"species"},
      {"key":"creatures","label":"Creatures","icon":"\u{1F409}","entityTypeKey":"creature"},
      {"key":"items","label":"Items","icon":"\u{1F4E6}","entityTypeKey":"item","subTypes":["Weapons","Armour","Artefacts","Consumables","Materials","Quest Items"]},
      {"key":"lore","label":"Lore","icon":"\u{1F4D6}","entityTypeKey":"lore"},
      {"key":"timelines","label":"Timeline","icon":"\u{1F4C5}","isFeature":true}
    ]
  },
  {
    "category": "SYSTEM",
    "items": [
      {"key":"power_systems","label":"Power Systems","icon":"\u26A1","entityTypeKey":"power_system"},
      {"key":"classes","label":"Classes / Paths","icon":"\u{1F6E1}","entityTypeKey":"class_path"},
      {"key":"stats","label":"Stats","icon":"\u{1F4CA}","entityTypeKey":"stat"},
      {"key":"skills","label":"Skills / Abilities","icon":"\u2728","entityTypeKey":"skill_ability"},
      {"key":"traits","label":"Traits / Perks","icon":"\u{1F3AF}","entityTypeKey":"trait_perk"},
      {"key":"resources","label":"Resources","icon":"\u{1F48E}","entityTypeKey":"resource"},
      {"key":"system_rules","label":"System Rules","icon":"\u{1F4DC}","entityTypeKey":"system_rule"}
    ]
  },
  {
    "category": "PROGRESSION",
    "items": [
      {"key":"progression","label":"Progression","icon":"\u{1F4C8}","entityTypeKey":"progression"},
      {"key":"character_builds","label":"Character Builds","icon":"\u{1F3D7}","entityTypeKey":"character_build"},
      {"key":"skill_trees","label":"Skill Trees","icon":"\u{1F333}","entityTypeKey":"skill_tree"},
      {"key":"evolution","label":"Evolution","icon":"\u{1F98B}","entityTypeKey":"evolution"},
      {"key":"progression_events","label":"Progression Events","icon":"\u{1F389}","entityTypeKey":"progression_event"}
    ]
  },
  {
    "category": "EQUIPMENT",
    "items": [
      {"key":"equipment","label":"Equipment","icon":"\u2694\uFE0F","entityTypeKey":"equipment"},
      {"key":"inventory","label":"Inventory","icon":"\u{1F392}","entityTypeKey":"inventory"},
      {"key":"crafting","label":"Crafting","icon":"\u{1F528}","entityTypeKey":"crafting"},
      {"key":"economy","label":"Economy","icon":"\u{1F4B0}","entityTypeKey":"economy"}
    ]
  },
  {
    "category": "QUESTS",
    "items": [
      {"key":"quests","label":"Quests","icon":"\u{1F9ED}","entityTypeKey":"quest"},
      {"key":"achievements","label":"Achievements / Titles","icon":"\u{1F3C6}","entityTypeKey":"achievement"},
      {"key":"rewards","label":"Rewards / Loot","icon":"\u{1F381}","entityTypeKey":"reward"}
    ]
  },
  {
    "category": "STORY",
    "items": [
      {"key":"story_threads","label":"Story Threads","icon":"\u{1F9F5}","entityTypeKey":"story_thread"},
      {"key":"mysteries","label":"Mysteries / Secrets","icon":"\u{1F50D}","entityTypeKey":"mystery"},
      {"key":"foreshadowing","label":"Foreshadowing","icon":"\u{1F52E}","entityTypeKey":"foreshadowing"},
      {"key":"setups_payoffs","label":"Setups / Payoffs","icon":"\u{1F3AC}","entityTypeKey":"setup_payoff"},
      {"key":"easter_eggs","label":"Easter Eggs","icon":"\u{1F95A}","entityTypeKey":"easter_egg"}
    ]
  },
  {
    "category": "RELATIONSHIPS",
    "items": [
      {"key":"relationships","label":"Relationships","icon":"\u{1F49E}","entityTypeKey":"relationship"},
      {"key":"knowledge_states","label":"Knowledge States","icon":"\u{1F9E0}","entityTypeKey":"knowledge_state"}
    ]
  },
  {
    "category": "REFERENCE",
    "items": [
      {"key":"maps","label":"Maps","icon":"\u{1F5FA}\uFE0F","entityTypeKey":"map"},
      {"key":"documents","label":"Documents","icon":"\u{1F4C4}","entityTypeKey":"document"},
      {"key":"glossary","label":"Glossary","icon":"\u{1F4D6}","entityTypeKey":"glossary"},
      {"key":"connections","label":"Connections","icon":"\u{1F500}","isFeature":true},
      {"key":"mentions","label":"Mentions","icon":"\u{1F4AC}","isFeature":true},
      {"key":"assets","label":"Assets","icon":"\u{1F4CE}","isFeature":true},
      {"key":"tags","label":"Tags","icon":"\u{1F3F7}\uFE0F","isFeature":true}
    ]
  }
]'::jsonb, TRUE, 10);

-- Standard Fantasy
INSERT INTO codex_format_presets (key, name, description, tree_definition, is_builtin, sort_order) VALUES
('standard_fantasy', 'Standard Fantasy', 'Classic fantasy world-building with magic, cultures, and epic story arcs.',
'[
  {
    "category": "CORE",
    "items": [
      {"key":"characters","label":"Characters","icon":"\u{1F464}","entityTypeKey":"character"},
      {"key":"locations","label":"Locations","icon":"\u{1F4CD}","entityTypeKey":"location"},
      {"key":"organisations","label":"Organisations","icon":"\u{1F3E2}","entityTypeKey":"organisation"},
      {"key":"families","label":"Families / Houses","icon":"\u{1F465}","entityTypeKey":"family"},
      {"key":"species","label":"Species","icon":"\u{1F43E}","entityTypeKey":"species"},
      {"key":"cultures","label":"Cultures","icon":"\u{1F30D}","entityTypeKey":"culture"},
      {"key":"creatures","label":"Creatures","icon":"\u{1F409}","entityTypeKey":"creature"},
      {"key":"items","label":"Items / Artefacts","icon":"\u{1F4E6}","entityTypeKey":"item"},
      {"key":"lore","label":"Lore","icon":"\u{1F4D6}","entityTypeKey":"lore"},
      {"key":"timelines","label":"Timeline","icon":"\u{1F4C5}","isFeature":true}
    ]
  },
  {
    "category": "WORLD",
    "items": [
      {"key":"magic_systems","label":"Magic Systems","icon":"\u26A1","entityTypeKey":"magic_system"},
      {"key":"religions","label":"Religions","icon":"\u{1F54C}","entityTypeKey":"religion"},
      {"key":"governments","label":"Governments","icon":"\u{1F3DB}\uFE0F","entityTypeKey":"government"},
      {"key":"languages","label":"Languages","icon":"\u{1F4AC}","entityTypeKey":"language"},
      {"key":"history","label":"History / Eras","icon":"\u{1F4D6}","entityTypeKey":"history_era"},
      {"key":"realms","label":"Realms / Dimensions","icon":"\u{1F30C}","entityTypeKey":"realm_dimension"}
    ]
  },
  {
    "category": "STORY",
    "items": [
      {"key":"story_threads","label":"Story Threads","icon":"\u{1F9F5}","entityTypeKey":"story_thread"},
      {"key":"character_arcs","label":"Character Arcs","icon":"\u{1F4C8}","entityTypeKey":"character_arc"},
      {"key":"mysteries","label":"Mysteries / Secrets","icon":"\u{1F50D}","entityTypeKey":"mystery"},
      {"key":"foreshadowing","label":"Foreshadowing","icon":"\u{1F52E}","entityTypeKey":"foreshadowing"},
      {"key":"setups_payoffs","label":"Setups / Payoffs","icon":"\u{1F3AC}","entityTypeKey":"setup_payoff"},
      {"key":"easter_eggs","label":"Easter Eggs","icon":"\u{1F95A}","entityTypeKey":"easter_egg"}
    ]
  },
  {
    "category": "RELATIONSHIPS",
    "items": [
      {"key":"relationships","label":"Relationships","icon":"\u{1F49E}","entityTypeKey":"relationship"},
      {"key":"knowledge_states","label":"Knowledge States","icon":"\u{1F9E0}","entityTypeKey":"knowledge_state"}
    ]
  },
  {
    "category": "REFERENCE",
    "items": [
      {"key":"maps","label":"Maps","icon":"\u{1F5FA}\uFE0F","entityTypeKey":"map"},
      {"key":"documents","label":"Documents","icon":"\u{1F4C4}","entityTypeKey":"document"},
      {"key":"glossary","label":"Glossary","icon":"\u{1F4D6}","entityTypeKey":"glossary"},
      {"key":"connections","label":"Connections","icon":"\u{1F500}","isFeature":true},
      {"key":"mentions","label":"Mentions","icon":"\u{1F4AC}","isFeature":true},
      {"key":"assets","label":"Assets","icon":"\u{1F4CE}","isFeature":true},
      {"key":"tags","label":"Tags","icon":"\u{1F3F7}\uFE0F","isFeature":true}
    ]
  }
]'::jsonb, TRUE, 20);

-- Contemporary / Earth-based
INSERT INTO codex_format_presets (key, name, description, tree_definition, is_builtin, sort_order) VALUES
('contemporary', 'Contemporary', 'Real-world stories focused on character relationships, conflicts, and personal arcs.',
'[
  {
    "category": "CORE",
    "items": [
      {"key":"characters","label":"Characters","icon":"\u{1F464}","entityTypeKey":"character"},
      {"key":"locations","label":"Locations","icon":"\u{1F4CD}","entityTypeKey":"location"},
      {"key":"organisations","label":"Organisations","icon":"\u{1F3E2}","entityTypeKey":"organisation"},
      {"key":"objects","label":"Objects","icon":"\u{1F4E6}","entityTypeKey":"item"},
      {"key":"timelines","label":"Timeline","icon":"\u{1F4C5}","isFeature":true}
    ]
  },
  {
    "category": "RELATIONSHIPS",
    "items": [
      {"key":"relationships","label":"Relationships","icon":"\u{1F49E}","entityTypeKey":"relationship"},
      {"key":"family","label":"Family","icon":"\u{1F46A}","entityTypeKey":"family"},
      {"key":"social_circle","label":"Friends / Social Circle","icon":"\u{1F91D}","entityTypeKey":"social_circle"}
    ]
  },
  {
    "category": "STORY",
    "items": [
      {"key":"character_arcs","label":"Character Arcs","icon":"\u{1F4C8}","entityTypeKey":"character_arc"},
      {"key":"romantic_arcs","label":"Romantic Arc","icon":"\u{1F496}","entityTypeKey":"romantic_arc"},
      {"key":"secrets","label":"Secrets","icon":"\u{1F512}","entityTypeKey":"secret"},
      {"key":"conflicts","label":"Conflicts","icon":"\u{1F4A5}","entityTypeKey":"conflict"},
      {"key":"story_threads","label":"Story Threads","icon":"\u{1F9F5}","entityTypeKey":"story_thread"},
      {"key":"foreshadowing","label":"Foreshadowing / Setups / Payoffs","icon":"\u{1F52E}","entityTypeKey":"foreshadowing"}
    ]
  },
  {
    "category": "REFERENCE",
    "items": [
      {"key":"documents","label":"Documents","icon":"\u{1F4C4}","entityTypeKey":"document"},
      {"key":"maps","label":"Maps","icon":"\u{1F5FA}\uFE0F","entityTypeKey":"map"},
      {"key":"glossary","label":"Glossary / Notes","icon":"\u{1F4D6}","entityTypeKey":"glossary"},
      {"key":"connections","label":"Connections","icon":"\u{1F500}","isFeature":true},
      {"key":"mentions","label":"Mentions","icon":"\u{1F4AC}","isFeature":true},
      {"key":"tags","label":"Tags","icon":"\u{1F3F7}\uFE0F","isFeature":true}
    ]
  }
]'::jsonb, TRUE, 30);
