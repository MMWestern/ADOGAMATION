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
      {"key":"characters","label":"Characters","icon":"👤","entityTypeKey":"character"},
      {"key":"locations","label":"Locations","icon":"📍","entityTypeKey":"location"},
      {"key":"organisations","label":"Organisations","icon":"🏢","entityTypeKey":"organisation"},
      {"key":"species","label":"Species","icon":"🐾","entityTypeKey":"species"},
      {"key":"creatures","label":"Creatures","icon":"🐉","entityTypeKey":"creature"},
      {"key":"items","label":"Items","icon":"📦","entityTypeKey":"item","subTypes":["Weapons","Armour","Artefacts","Consumables","Materials","Quest Items"]},
      {"key":"lore","label":"Lore","icon":"📖","entityTypeKey":"lore"},
      {"key":"timelines","label":"Timeline","icon":"📅","isFeature":true}
    ]
  },
  {
    "category": "SYSTEM",
    "items": [
      {"key":"power_systems","label":"Power Systems","icon":"⚡","entityTypeKey":"power_system"},
      {"key":"classes","label":"Classes / Paths","icon":"🛡","entityTypeKey":"class_path"},
      {"key":"stats","label":"Stats","icon":"📊","entityTypeKey":"stat"},
      {"key":"skills","label":"Skills / Abilities","icon":"✨","entityTypeKey":"skill_ability"},
      {"key":"traits","label":"Traits / Perks","icon":"🎯","entityTypeKey":"trait_perk"},
      {"key":"resources","label":"Resources","icon":"💎","entityTypeKey":"resource"},
      {"key":"system_rules","label":"System Rules","icon":"📜","entityTypeKey":"system_rule"}
    ]
  },
  {
    "category": "PROGRESSION",
    "items": [
      {"key":"progression","label":"Progression","icon":"📈","entityTypeKey":"progression"},
      {"key":"character_builds","label":"Character Builds","icon":"🏗","entityTypeKey":"character_build"},
      {"key":"skill_trees","label":"Skill Trees","icon":"🌳","entityTypeKey":"skill_tree"},
      {"key":"evolution","label":"Evolution","icon":"🦋","entityTypeKey":"evolution"},
      {"key":"progression_events","label":"Progression Events","icon":"🎉","entityTypeKey":"progression_event"}
    ]
  },
  {
    "category": "EQUIPMENT",
    "items": [
      {"key":"equipment","label":"Equipment","icon":"⚔️","entityTypeKey":"equipment"},
      {"key":"inventory","label":"Inventory","icon":"🎒","entityTypeKey":"inventory"},
      {"key":"crafting","label":"Crafting","icon":"🔨","entityTypeKey":"crafting"},
      {"key":"economy","label":"Economy","icon":"💰","entityTypeKey":"economy"}
    ]
  },
  {
    "category": "QUESTS",
    "items": [
      {"key":"quests","label":"Quests","icon":"🧭","entityTypeKey":"quest"},
      {"key":"achievements","label":"Achievements / Titles","icon":"🏆","entityTypeKey":"achievement"},
      {"key":"rewards","label":"Rewards / Loot","icon":"🎁","entityTypeKey":"reward"}
    ]
  },
  {
    "category": "STORY",
    "items": [
      {"key":"story_threads","label":"Story Threads","icon":"🧵","entityTypeKey":"story_thread"},
      {"key":"mysteries","label":"Mysteries / Secrets","icon":"🔍","entityTypeKey":"mystery"},
      {"key":"foreshadowing","label":"Foreshadowing","icon":"🔮","entityTypeKey":"foreshadowing"},
      {"key":"setups_payoffs","label":"Setups / Payoffs","icon":"🎬","entityTypeKey":"setup_payoff"},
      {"key":"easter_eggs","label":"Easter Eggs","icon":"🥚","entityTypeKey":"easter_egg"}
    ]
  },
  {
    "category": "RELATIONSHIPS",
    "items": [
      {"key":"relationships","label":"Relationships","icon":"💞","entityTypeKey":"relationship"},
      {"key":"knowledge_states","label":"Knowledge States","icon":"🧠","entityTypeKey":"knowledge_state"}
    ]
  },
  {
    "category": "REFERENCE",
    "items": [
      {"key":"maps","label":"Maps","icon":"🗺️","entityTypeKey":"map"},
      {"key":"documents","label":"Documents","icon":"📄","entityTypeKey":"document"},
      {"key":"glossary","label":"Glossary","icon":"📖","entityTypeKey":"glossary"},
      {"key":"connections","label":"Connections","icon":"🔀","isFeature":true},
      {"key":"mentions","label":"Mentions","icon":"💬","isFeature":true},
      {"key":"assets","label":"Assets","icon":"📎","isFeature":true},
      {"key":"tags","label":"Tags","icon":"🏷️","isFeature":true}
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
      {"key":"characters","label":"Characters","icon":"👤","entityTypeKey":"character"},
      {"key":"locations","label":"Locations","icon":"📍","entityTypeKey":"location"},
      {"key":"organisations","label":"Organisations","icon":"🏢","entityTypeKey":"organisation"},
      {"key":"families","label":"Families / Houses","icon":"👥","entityTypeKey":"family"},
      {"key":"species","label":"Species","icon":"🐾","entityTypeKey":"species"},
      {"key":"cultures","label":"Cultures","icon":"🌍","entityTypeKey":"culture"},
      {"key":"creatures","label":"Creatures","icon":"🐉","entityTypeKey":"creature"},
      {"key":"items","label":"Items / Artefacts","icon":"📦","entityTypeKey":"item"},
      {"key":"lore","label":"Lore","icon":"📖","entityTypeKey":"lore"},
      {"key":"timelines","label":"Timeline","icon":"📅","isFeature":true}
    ]
  },
  {
    "category": "WORLD",
    "items": [
      {"key":"magic_systems","label":"Magic Systems","icon":"⚡","entityTypeKey":"magic_system"},
      {"key":"religions","label":"Religions","icon":"🕌","entityTypeKey":"religion"},
      {"key":"governments","label":"Governments","icon":"🏛️","entityTypeKey":"government"},
      {"key":"languages","label":"Languages","icon":"💬","entityTypeKey":"language"},
      {"key":"history","label":"History / Eras","icon":"📖","entityTypeKey":"history_era"},
      {"key":"realms","label":"Realms / Dimensions","icon":"🌌","entityTypeKey":"realm_dimension"}
    ]
  },
  {
    "category": "STORY",
    "items": [
      {"key":"story_threads","label":"Story Threads","icon":"🧵","entityTypeKey":"story_thread"},
      {"key":"character_arcs","label":"Character Arcs","icon":"📈","entityTypeKey":"character_arc"},
      {"key":"mysteries","label":"Mysteries / Secrets","icon":"🔍","entityTypeKey":"mystery"},
      {"key":"foreshadowing","label":"Foreshadowing","icon":"🔮","entityTypeKey":"foreshadowing"},
      {"key":"setups_payoffs","label":"Setups / Payoffs","icon":"🎬","entityTypeKey":"setup_payoff"},
      {"key":"easter_eggs","label":"Easter Eggs","icon":"🥚","entityTypeKey":"easter_egg"}
    ]
  },
  {
    "category": "RELATIONSHIPS",
    "items": [
      {"key":"relationships","label":"Relationships","icon":"💞","entityTypeKey":"relationship"},
      {"key":"knowledge_states","label":"Knowledge States","icon":"🧠","entityTypeKey":"knowledge_state"}
    ]
  },
  {
    "category": "REFERENCE",
    "items": [
      {"key":"maps","label":"Maps","icon":"🗺️","entityTypeKey":"map"},
      {"key":"documents","label":"Documents","icon":"📄","entityTypeKey":"document"},
      {"key":"glossary","label":"Glossary","icon":"📖","entityTypeKey":"glossary"},
      {"key":"connections","label":"Connections","icon":"🔀","isFeature":true},
      {"key":"mentions","label":"Mentions","icon":"💬","isFeature":true},
      {"key":"assets","label":"Assets","icon":"📎","isFeature":true},
      {"key":"tags","label":"Tags","icon":"🏷️","isFeature":true}
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
      {"key":"characters","label":"Characters","icon":"👤","entityTypeKey":"character"},
      {"key":"locations","label":"Locations","icon":"📍","entityTypeKey":"location"},
      {"key":"organisations","label":"Organisations","icon":"🏢","entityTypeKey":"organisation"},
      {"key":"objects","label":"Objects","icon":"📦","entityTypeKey":"item"},
      {"key":"timelines","label":"Timeline","icon":"📅","isFeature":true}
    ]
  },
  {
    "category": "RELATIONSHIPS",
    "items": [
      {"key":"relationships","label":"Relationships","icon":"💞","entityTypeKey":"relationship"},
      {"key":"family","label":"Family","icon":"👪","entityTypeKey":"family"},
      {"key":"social_circle","label":"Friends / Social Circle","icon":"🤝","entityTypeKey":"social_circle"}
    ]
  },
  {
    "category": "STORY",
    "items": [
      {"key":"character_arcs","label":"Character Arcs","icon":"📈","entityTypeKey":"character_arc"},
      {"key":"romantic_arcs","label":"Romantic Arc","icon":"💖","entityTypeKey":"romantic_arc"},
      {"key":"secrets","label":"Secrets","icon":"🔒","entityTypeKey":"secret"},
      {"key":"conflicts","label":"Conflicts","icon":"💥","entityTypeKey":"conflict"},
      {"key":"story_threads","label":"Story Threads","icon":"🧵","entityTypeKey":"story_thread"},
      {"key":"foreshadowing","label":"Foreshadowing / Setups / Payoffs","icon":"🔮","entityTypeKey":"foreshadowing"}
    ]
  },
  {
    "category": "REFERENCE",
    "items": [
      {"key":"documents","label":"Documents","icon":"📄","entityTypeKey":"document"},
      {"key":"maps","label":"Maps","icon":"🗺️","entityTypeKey":"map"},
      {"key":"glossary","label":"Glossary / Notes","icon":"📖","entityTypeKey":"glossary"},
      {"key":"connections","label":"Connections","icon":"🔀","isFeature":true},
      {"key":"mentions","label":"Mentions","icon":"💬","isFeature":true},
      {"key":"tags","label":"Tags","icon":"🏷️","isFeature":true}
    ]
  }
]'::jsonb, TRUE, 30);
