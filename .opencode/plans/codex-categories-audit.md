# Codex Categories & Entity Types — Full Audit

## How It Works

- **Presets** define a tree of categories → items. Each item has an `entityTypeKey` linking it to a DB entity type.
- **`all_types`** is the BASE preset (is_base: true). Derived presets (litrpg, standard_fantasy, contemporary) inherit from it and toggle items on/off.
- **`CODEX_TREE_DEF`** is a minimal fallback tree used when no preset is loaded.
- **Entity types** are seeded in Supabase `codex_entity_types` table via migrations.

---

## 1. Current Preset Structures

### BASE: `all_types` (All Types)

| Category | Item Label | entityTypeKey | SubTypes |
|----------|-----------|---------------|----------|
| **CORE** | Characters | character | Protagonist, Antagonist, Supporting, Minor, Mentioned |
| | Locations | location | City, Village, Forest, Mountain, Dungeon, Realm, Home, Workplace, Public, Travel, Other |
| | Organisations | organisation | Guild, Faction, Government, Military, Religious, Criminal, Academic, Other |
| | Families / Houses | family | Noble, Common, Royal, Ancient, Other |
| | Species | species | Humanoid, Beast, Plant, Elemental, Other |
| | Cultures | culture | Tribal, Nomadic, Urban, Maritime, Other |
| | Creatures | creature | Beasts, Monsters, Dragons, Undead, Spirits, Other |
| | Items / Artefacts | item | Weapons, Armour, Artefacts, Consumables, Materials, Quest Items, Personal, Documents, Technology, Keepsakes, Other |
| | Lore | lore | History, Mythology, Magic Rules, Prophecies, Legends, Other |
| | Timeline | *(isFeature: true)* | — |
| **WORLD** | Magic Systems | magic_system | Elemental, Divine, Arcane, Ritual, Innate, Other |
| | Power Systems | power_system | Tiered, Linear, Branching, Hybrid, Other |
| | Religions | religion | Monotheistic, Polytheistic, Animistic, Cult, Philosophy, Other |
| | Governments | government | Monarchy, Democracy, Theocracy, Oligarchy, Tribal, Anarchy, Other |
| | Languages | language | Spoken, Written, Magical, Sign, Other |
| | History / Eras | history_era | Ancient, Medieval, Renaissance, Modern, Future, Mythological, Other |
| | Realms / Dimensions | realm_dimension | Physical, Astral, Ethereal, Shadow, Divine, Other |
| | System Rules | system_rule | Physics, Magic, Society, Economy, Other |
| **PROGRESSION** | Classes / Paths | class_path | Warrior, Mage, Rogue, Healer, Hybrid, Other |
| | Stats | stat | Primary, Secondary, Derived, Other |
| | Skills / Abilities | skill_ability | Active, Passive, Ultimate, Crafting, Social, Other |
| | Traits / Perks | trait_perk | Racial, Class, Background, Achievement, Other |
| | Resources | resource | Mana, Stamina, Gold, Materials, Tokens, Other |
| | Progression | progression | Level, Rank, Tier, Stage, Other |
| | Character Builds | character_build | PvE, PvP, Hybrid, Support, Other |
| | Skill Trees | skill_tree | Combat, Magic, Crafting, Social, Other |
| | Evolution | evolution | Class Evolution, Species Evolution, Ascension, Mutation, Other |
| | Progression Events | progression_event | Level Up, Breakthrough, Achievement, Unlock, Other |
| **EQUIPMENT** | Equipment | equipment | Weapon, Armour, Accessory, Tool, Mount, Other |
| | Inventory | inventory | Bag, Storage, Vault, Shared, Other |
| | Crafting | crafting | Blacksmithing, Alchemy, Enchanting, Cooking, Tailoring, Other |
| | Economy | economy | Currency, Trade, Market, Banking, Other |
| **QUESTS** | Quests | quest | Main, Side, Daily, Hidden, Chain, Other |
| | Achievements / Titles | achievement | Combat, Exploration, Social, Crafting, Collection, Other |
| | Rewards / Loot | reward | Item, Currency, Experience, Title, Unlock, Other |
| **STORY** | Story Threads | story_thread | Main Plot, Subplot, Side Story, Flashback, Other |
| | Character Arcs | character_arc | Growth, Fall, Redemption, Tragedy, Flat, Other |
| | Mysteries / Secrets | mystery | Whodunit, Whydunit, Howdunit, What Is It, Other |
| | Foreshadowing | foreshadowing | Direct, Indirect, Symbolic, Chekhov's Gun, Red Herring, Other |
| | Setups / Payoffs | setup_payoff | Setup, Payoff, Both, Other |
| | Easter Eggs | easter_egg | Reference, Homage, Meta, Hidden, Other |
| | Romantic Arc | romantic_arc | Slow Burn, Love Triangle, Second Chance, Forbidden, Enemies to Lovers, Other |
| | Secrets | secret | Character, World, Plot, Identity, Other |
| | Conflicts | conflict | Internal, Interpersonal, Societal, Environmental, Other |
| **RELATIONSHIPS** | Relationships | relationship | Ally, Enemy, Rival, Mentor, Student, Love Interest, Family, Other |
| | Knowledge States | knowledge_state | Known, Unknown, Partially Known, Misunderstood, Other |
| | Friends / Social Circle | social_circle | Close Friend, Acquaintance, Colleague, Neighbor, Other |
| **META** | Continuity Notes | continuity_note | Plot Hole, Contradiction, Timeline Issue, Character Inconsistency, Other |
| | Journal / Notes | journal | Research, Ideas, To-Do, Reference, Other |
| **REFERENCE** | Maps | map | World, Region, City, Building, Dungeon, Other |
| | Documents | document | Letter, Contract, Prophecy, Diary, Official, Other |
| | Glossary | glossary | Term, Phrase, Name, Title, Other |
| | Connections | *(isFeature: true)* | — |
| | Mentions | *(isFeature: true)* | — |
| | Assets | *(isFeature: true)* | — |
| | Tags | *(isFeature: true)* | — |

### Derived: `standard_fantasy` (Standard Fantasy)

| Category | Items (subset of all_types) | Differences from all_types |
|----------|---------------------------|---------------------------|
| **CORE** | Characters, Locations, Organisations, Families/Houses, Species, Cultures, Creatures, Items/Artefacts, Lore, Timeline | Fewer subTypes per item |
| **WORLD** | Magic Systems, Religions, Governments, Languages, History/Eras, Realms/Dimensions | Missing: Power Systems, System Rules |
| **STORY** | Story Threads, Character Arcs, Mysteries/Secrets, Foreshadowing, Setups/Payoffs, Easter Eggs | Missing: Romantic Arc, Secrets, Conflicts |
| **RELATIONSHIPS** | Relationships, Knowledge States | Missing: Social Circle |
| **REFERENCE** | Maps, Documents, Glossary, Connections, Mentions, Assets, Tags | Same |

### Derived: `litrpg` (LitRPG)

| Category | Items (subset of all_types) | Unique to LitRPG |
|----------|---------------------------|-----------------|
| **CORE** | Characters, Locations, Organisations, Species, Creatures, Items, Lore, Timeline | Missing: Families, Cultures |
| **SYSTEM** | Power Systems, Classes/Paths, Stats, Skills/Abilities, Traits/Perks, Resources, System Rules | Renamed WORLD → SYSTEM |
| **PROGRESSION** | Progression, Character Builds, Skill Trees, Evolution, Progression Events | Same |
| **EQUIPMENT** | Equipment, Inventory, Crafting, Economy | Same |
| **QUESTS** | Quests, Achievements/Titles, Rewards/Loot | Same |
| **STORY** | Story Threads, Mysteries/Secrets, Foreshadowing, Setups/Payoffs, Easter Eggs | Missing: Character Arcs, Romantic Arc, Secrets, Conflicts |
| **RELATIONSHIPS** | Relationships, Knowledge States | Missing: Social Circle |
| **REFERENCE** | Maps, Documents, Glossary, Connections, Mentions, Assets, Tags | Same |

### Derived: `contemporary` (Contemporary)

| Category | Items (subset of all_types) | Unique to Contemporary |
|----------|---------------------------|----------------------|
| **CORE** | Characters, Locations, Organisations, Objects, Timeline | No: Species, Cultures, Creatures, Lore, Families |
| **RELATIONSHIPS** | Relationships, Family, Friends/Social Circle | Family moved here from CORE |
| **STORY** | Character Arcs, Romantic Arc, Secrets, Conflicts, Story Threads, Foreshadowing/Setups/Payoffs | Different grouping |
| **REFERENCE** | Documents, Maps, Glossary/Notes, Connections, Mentions, Tags | Missing: Assets |

### Fallback: `CODEX_TREE_DEF` (minimal)

| Category | Items |
|----------|-------|
| **Narrative** | Characters, Locations, Objects, Organisations, Families, Subplots (→ quest), Lore |
| **Systems** | Magic Systems, Maps, Timelines |
| **Meta** | Continuity, Other/Journal, Connections, Mentions, Assets, AI Tools |

---

## 2. All Unique Entity Types (from DB migrations)

### Migration 1: `20260604_create_codex_entity_types.sql`
| Key | Singular | Plural | is_system |
|-----|----------|--------|-----------|
| character | Character | Characters | TRUE |
| location | Location | Locations | TRUE |
| organisation | Organisation | Organisations | TRUE |
| family | Family | Families | TRUE |
| item | Item | Items | TRUE |
| lore | Lore | Lore | TRUE |
| quest | Quest | Quests | TRUE |
| journal | Journal | Journals | TRUE |
| continuity_note | Continuity Note | Continuity Notes | TRUE |

### Migration 2: `20260607_add_worldbuilding_entity_types.sql`
| Key | Singular | Plural |
|-----|----------|--------|
| map | Map | Maps |
| magic_system | Magic System | Magic Systems |

### Migration 3: `20260827_seed_new_entity_types.sql`
| Key | Singular | Plural | Category |
|-----|----------|--------|----------|
| species | Species | Species | Shared |
| creature | Creature | Creatures | Shared |
| story_thread | Story Thread | Story Threads | Shared |
| mystery | Mystery / Secret | Mysteries / Secrets | Shared |
| foreshadowing | Foreshadowing | Foreshadowing | Shared |
| setup_payoff | Setup / Payoff | Setups / Payoffs | Shared |
| easter_egg | Easter Egg | Easter Eggs | Shared |
| relationship | Relationship | Relationships | Shared |
| knowledge_state | Knowledge State | Knowledge States | Shared |
| document | Document | Documents | Shared |
| glossary | Glossary Entry | Glossary | Shared |
| character_arc | Character Arc | Character Arcs | Shared |
| power_system | Power System | Power Systems | LitRPG |
| class_path | Class / Path | Classes / Paths | LitRPG |
| stat | Stat | Stats | LitRPG |
| skill_ability | Skill / Ability | Skills / Abilities | LitRPG |
| trait_perk | Trait / Perk | Traits / Perks | LitRPG |
| resource | Resource | Resources | LitRPG |
| system_rule | System Rule | System Rules | LitRPG |
| progression | Progression | Progression | LitRPG |
| character_build | Character Build | Character Builds | LitRPG |
| skill_tree | Skill Tree | Skill Trees | LitRPG |
| evolution | Evolution | Evolution | LitRPG |
| progression_event | Progression Event | Progression Events | LitRPG |
| equipment | Equipment | Equipment | LitRPG |
| inventory | Inventory | Inventory | LitRPG |
| crafting | Crafting | Crafting | LitRPG |
| economy | Economy | Economy | LitRPG |
| achievement | Achievement / Title | Achievements / Titles | LitRPG |
| reward | Reward / Loot | Rewards / Loot | LitRPG |
| religion | Religion | Religions | Std Fantasy |
| government | Government | Governments | Std Fantasy |
| language | Language | Languages | Std Fantasy |
| history_era | History / Era | History / Eras | Std Fantasy |
| realm_dimension | Realm / Dimension | Realms / Dimensions | Std Fantasy |
| culture | Culture | Cultures | Std Fantasy |
| social_circle | Social Circle | Social Circles | Contemporary |
| romantic_arc | Romantic Arc | Romantic Arcs | Contemporary |
| secret | Secret | Secrets | Contemporary |
| conflict | Conflict | Conflicts | Contemporary |

**Total: 49 entity types in DB**

---

## 3. Entity Detail Panel — What Exists Per Entity Type

### Universal Fields (all entity types)
- Name (textarea)
- Sub-type (dropdown from tree definition subTypes, or free text)
- Scope (series / wiki / specific book)
- Status (draft / active / archived)
- Canon Status (draft / provisional / canon / deprecated)
- Visibility (private / author_only / public)
- Spoiler Level (none / mild / major / secret)
- Color tag
- Image
- Description (tab)
- Backstory (tab)
- Revision History (tab)
- Custom sections: Physical Description, Personality Summary, Traits, Core Motivation, Background, Strengths, Flaws, Fears, Internal Conflict, External Conflict, Quirks, Dialogue Style, Arc Notes, Secrets, Notes

### Character-Specific Fields
- Role dropdown (from `character_role` inspector options)
- Archetype dropdown (from `character_archetype` — The Hero, The Mentor, The Shadow, etc.)
- Motivation / Arc dropdown (from `motivation_arc` — Flat/Steadfast, Positive Change, etc.)

### Location-Specific Fields
- Parent Location dropdown (links to other locations via `located_in` connection)
- Location breadcrumb navigation
- Sibling locations display

### All Other Entity Types (47 types)
- **Generic fields only** — no type-specific dropdowns or panels
- Organisation: no "type" dropdown (guild vs govt vs faction)
- Item: no "material", "weight", "rarity" fields
- Magic System: no "source", "cost", "limitations" fields
- Species: no "lifespan", "habitat", "traits" fields
- Religion: no "deity", "tenets", "structure" fields
- Government: no "leader", "laws", "succession" fields
- etc.

---

## 4. How Entities Link to Each Other

### Connections System (`codex_connections` table)
- `source_entity_id` → `target_entity_id` with `relationship_type_id`
- `codex_relationship_types` defines types (e.g. `located_in` with forward/inverse labels)
- Used for: parent location, character relationships, general connections

### Relationships Panel (right column)
- Shows connections for selected entity
- Can add/edit/delete connections
- Click to navigate to connected entity

### Two Relationship Systems
1. **`codex_connections`** — DB table, typed relationships between any two entities
2. **`relationship` entity type** — an entity that describes a relationship (redundant?)

---

## 5. Issues & Gaps Identified

### Category Structure Issues
1. **Families** is CORE but could be a sub-type of Organisation or a relationship type
2. **Cultures** is CORE but could be a sub-type of Species or a WORLD item
3. **Species** and **Creatures** overlap — species = sentient, creatures = non-sentient
4. **Lore** is extremely broad — covers History, Mythology, Magic Rules, Prophecies, Legends
5. **Magic Systems** and **Power Systems** are separate items but very similar
6. **Progression** category has 10 items — most are LitRPG-specific
7. **Equipment** overlaps with Items (item has Weapons/Armour subTypes)
8. **Quests** overlaps with Story Threads (both cover plot arcs)
9. **Relationships** entity type vs Connections system — two mechanisms
10. **Knowledge States** in RELATIONSHIPS but could be META
11. **Social Circle** only in Contemporary — could be universal
12. **Secrets** and **Mysteries/Secrets** overlap in Contemporary

### Missing Entity-Specific Panels
- Characters: role, archetype, motivation — good
- Locations: parent location, breadcrumb — good
- **All 47 other types**: generic fields only — no type-specific dropdowns

### Duplicate / Overlapping Concepts
- `item` vs `equipment` — both cover weapons/armour
- `quest` vs `story_thread` — both cover plot arcs
- `lore` vs `history_era`, `mystery`, `glossary` — lore is a catch-all
- `relationship` entity vs `codex_connections` table — two relationship systems

### Features (isFeature: true) — Not Entity Types
- Timeline, Connections, Mentions, Assets, Tags, AI Tools
- These are UI features, not database entity types
