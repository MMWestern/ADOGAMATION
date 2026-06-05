# Changelog

## v1.2.0 (2026-06-05) — Codex Inspector, Image Picker Enhancements & AI Generator Modes

### Features

#### Codex Inspector Panel
- **Persistent inspector panel** replaces popup modals for editing codex entities in the CODEX tab
- Generic form with name, badge, role/archetype (characters), scope, description, secondary/tertiary notes, color picker, image
- Click any entity in Characters/Locations/Objects/Lore lists → inspector opens with entity details
- "+ Add" buttons open inspector in create mode
- Save creates/updates via `saveCodexEntity` / `mapLegacySavePayloadToCodex_`
- Delete with confirmation
- Color picker affects title color (matches other codex positions)
- Clickable image opens image picker with context-aware category filter
- Role and archetype dropdowns for characters (populated from `DEFAULT_CHARACTER_ROLES` / `DEFAULT_CHARACTER_ARCHETYPES`)
- "Generate Image" button opens AI generator in Codex Asset mode

#### Image Picker Enhancements
- **Category filter bar** — filter images by All, Characters, Locations, Objects, Covers, Scenes, General
- **Context-aware defaults** — project/series images default to "cover" filter, codex inspector defaults to entity type filter
- **Meta panel** — shows selected image thumbnail, filename, category dropdown; category auto-saves on change
- **Crop tool** — crop modal with aspect ratio buttons (Free, 1:1, 3:4, 16:9), draggable/resizable crop box, canvas-based crop, uploads cropped variant to Supabase Storage
- **Category persistence** — `category` column on `image_assets` table, auto-categorized on upload

#### AI Image Generator Modes
- **Mode toggle** — "Book Cover" / "Codex Asset" buttons at top of generator modal
- **Book Cover mode** — unchanged (typography, text placement, font style, series tools)
- **Codex Asset mode** — replaces text-related dropdowns with Pose/View, Setting, Lighting dropdowns
- **Codex prompt builder** — subject-focused prompt with codex-specific descriptors, no text/typography instructions
- **Different negative prompts** — cover mode excludes book mockups, codex mode excludes text overlays
- **Auto-category** — generated images uploaded with category matching entity type (character/location/object)
- **Pre-filled from entity** — pulls name, description, secondary/tertiary notes, badge/role from codex inspector or WRITING tab codex modal

#### Bug Fixes
- **Chapter drag-drop orphaning** — `splice` now happens after all validation; `dragend` reverts DOM if `drop` didn't fire
- **Book Creator 401 errors** — `runBookCreatorOutlineChain` now awaits `loadAISettings()` before building AI request
- **Book Creator payload mismatch** — `buildBookCreatorAIRequest` now sets flat `{ model, messages, temperature, max_tokens }` that `callEditorAI` expects
- **AI Settings persistence** — `applyAISettingsToForm` now handles flat Supabase format (not just nested); `loadAISettings()` called on app startup
- **Provider override bug** — removed `appState.aiSettings.activeProvider` override (was always undefined, defaulted to "openrouter")
- **AI Test popup context** — local context dropdown populated with heading-based options; project sources reduced to "Project Summary"
- **CODEX tab sub-tabs** — Characters/Locations/Objects/Lore lists now read from `codexCache` when new engine is active
- **Objects sub-tab** — added to CODEX tab with list, add button, and inspector integration
- **Lore sub-tab** — switches between legacy textarea and new engine list based on `USE_NEW_CODEX_ENGINE`

### Technical
- `image_assets` table: added `category` (text, default 'general') and `crop_data` (jsonb) columns
- New CRUD methods: `updateImageCategoryJsonFromClient`, `saveImageCropJsonFromClient`
- `loadAISettings()` now returns a Promise (was fire-and-forget)
- `openImagePickerModal(defaultFilter)` accepts optional filter parameter
- `openImageGeneratorModal(mode)` accepts "cover" or "codex" mode
- Image picker `targetMode` extended with "codexInspector" for codex context
- Crop modal z-index 1200 (above image picker at 1000)
- `_dragDropFired` guard flag prevents chapter orphaning on cancelled drags
- Migration: `migrations/20260605_add_image_category_crop.sql`

## v1.1.0 (2026-06-05) — CODEX Engine Rebuild

### Features
- **Phase 0-2:** Audit, schema migrations (16 codex tables), service layer with `_sbDefine`/`supabaseRunner`, view-model mappers with `pluralMap`
- **Phase 3-4:** KNOWLEDGE tab renamed to CODEX, read switching to new engine via `USE_NEW_CODEX_ENGINE` flag, `codexCache` for entities by series
- **Phase 5-6:** Save routing through new engine, plan outline codex tag/POV integration
- **Phase 7:** Connections sub-tab (add, list, save, delete) in CODEX panel
- **Phase 8:** Calendars, Events, Timelines sub-tabs + migration files for all remaining features
- **Phase 9:** Mentions sub-tab with full CRUD
- **Phase 10:** Content Assets sub-tab with full CRUD (title, type, content, audience, spoiler level, entity, status)
- **Phase 11:** AI Brainstorming sub-tab (generate suggestions, review/adopt/dismiss, detail view). Model resolution via `collectAISettingsFormData()` + `getSelectedAIModel()`. Dynamic AI provider badge (green/red, polls 5s, clickable to open AI Settings). Spinner with `.is-visible` class toggle.
- **Phase 12:** Semantic Retrieval — embedding generation via `callEditorEmbedding()`, cosine similarity search against `codex_embeddings` table. Generate Embeddings and Search UI in AI tab.
- **Phase 13:** Advanced Continuity Assistance — AI-powered contradiction scanning across entity descriptions, findings list with severity/status badges, Resolve/Dismiss/Auto-Fix buttons. Auto-Fix sends to AI tab for adopt/dismiss review.
- **Phase 14:** Retired 16 unused prototype tables (characters, locations, objects, lore, subplots, other + link tables). Legacy loads guarded behind feature flag. Continuity pickers updated to read from `codexCache`.

### Technical
- All new codex tables use BIGSERIAL IDs, match existing Supabase/`supabaseRunner`/`_sbDefine` patterns
- RLS on all new tables (broad authenticated-user, scoped by `series_id` FK)
- AI secrets kept client-side in localStorage form fields; no server-side proxy
- Dev server on port 3000 with recursive include processing, CORS headers, ComfyUI proxy
- Continuous build via `node build.js` → output in `build/`
- Migration files in `migrations/` directory, run manually in Supabase SQL editor

### Features
- Direct Supabase browser access (no Google Apps Script dependency)
- Project CRUD (create, read, update, delete)
- Series management with metadata
- Document sections (draft, outline, notes) with markdown content
- Image upload via Supabase Storage (project-images bucket)
- Image picker with lazy loading and caching
- AI settings stored in localStorage (LM Studio, Ollama, OpenRouter)
- AI completion via browser fetch to local providers
- Book Creator pockets from Supabase table
- Story Seed Engine from local JSON file
- ComfyUI image generation proxy
- Dark mode support
- Real-time status updates

### Technical
- Supabase direct browser access via UMD SDK
- supabaseRunner Proxy pattern for method interception
- _sbDefine pattern for incremental migration
- Dev server with no-cache headers
- Vercel deployment support
