# Silent Pixel — Codebase Handbook

## Architecture

**Build system**: `node build.js` — processes `<?!= include('scripts/...'); ?>` directives in `Client.html`, auto-appends `.html`, outputs to `build/`.

**Single-page app**: A monolithic `<script>` in `Client.html` (~5,680 lines remaining) with 22 extracted script modules. Core orchestration logic stays inline; independent features live in modules.

## Module Map (22 extracted, `scripts/*.html`, 10,608 total lines)

### Foundation (loaded first, lines ~1–53 of Client.html)
| Module | Lines | Purpose |
|--------|-------|---------|
| `auth.html` | 54 | `_initAuth()` — Supabase auth, sign-in/sign-out |
| `supabase-runner.html` | 126 | `supabaseRunner.*` proxy — calls server-side Apps Script / Supabase functions |
| `supabase-crud.html` | 238 | CRUD helpers (`saveProjectJsonFromClient`, `getProjectsJsonForClient`, etc.) |
| `utils.html` | 87 | `escapeHtml`, `titleCase`, `pillClass`, `stripHtmlTags`, etc. |
| `data-operations.html` | 777 | Data layer helpers |
| `constants.html` | 593 | All reference data / constants |
| `app-state.html` | 130 | `appState` singleton initialisation |
| `el-cache.html` | 581 | `el.*` DOM element cache (all `getElementById` calls) |
| `status-logging.html` | 119 | `setStatus`, `activeMainTab`, log functions |

### Features (loaded at specific points inline)
| Module | Lines | Purpose |
|--------|-------|---------|
| `series-meta.html` | 41 | `getSeriesMetaForProject`, `applySeriesMetaToProjects` |
| `inspector-options.html` | 244 | Filter/option CRUD for inspector panel |
| `series-knowledge.html` | 1,050 | Characters, locations, continuity CRUD + lore editor |
| `plan-outline.html` | 780 | Act/chapter/scene tree editing, drag/drop, codex tag linking |
| `image-generator.html` | 694 | ComfyUI workflow, prompt builder, history |
| `markdown-utils.html` | 792 | `renderMarkdownWithHeadingAnchors`, `getMarkdownHeadings`, word counting + **general UI utils** (`toggleSettingsMenu`, `toggleDarkMode`, `formatWordCount`) + **AI helpers** (`loadAISettings`, `collectAISettingsFormData`, `callEditorAI`, `fetchAIModels`) |
| `book-creator-helpers.html` | 762 | Book compilation helpers |
| `book-creator.html` | 1,263 | Book creator UI/flow |
| `schedule-templates.html` | 121 | Schedule template rendering |
| `marketing-templates.html` | 121 | Marketing template rendering |
| `campaigns.html` | 197 | Campaign list rendering |
| `resources-editor.html` | 567 | Resource editor panel CRUD |
| `bind-events.html` | 1,271 | `bindEvents()` — all DOM event bindings |

### Deleted (replaced by markdown-utils.html)
| Former module | Lines | Replacement |
|---------------|-------|-------------|
| `markdown-editor.html` | 840 | — |
| `markdown-editor-ui.html` | 3,575 | — |

## Inline Code Remaining in Client.html (~5,680 lines)

**Not extracted — core orchestration layer.** Interconnected coordination logic that connects all modules. Keeping it inline is deliberate; extracting would add risk with diminishing returns.

Key remaining areas:
- Writing workspace (codex, editor, loading, saving) — ~2,100 lines
- Image picker & image utils — ~700 lines
- Dashboard/landing page — ~620 lines
- Project CRUD (state, save/load, create) — ~580 lines
- Doc cache + field helpers — ~420 lines
- Detail form + image/link UI — ~460 lines
- Filters & projects table — ~250 lines
- Resource editor preview — ~250 lines
- Timeline + publishing/marketing — ~200 lines
- Bootstrap/init (cannot extract until all others are) — ~100 lines

## Recent & Important Fixes (commits on main)

| Fix | Commit |
|-----|--------|
| Dark mode persists via `applyDarkModePreference()` | `98528fc` |
| Timeline filter (series + project) persists | `e656731` |
| Timeline ghost mode persists | `508788b` |
| Timeline milestones saved to Supabase (`saveProjectJsonFromClient`) | `52cb867` |
| AI settings modal fixed (per-provider inputs, panel selectors) | `2f726dd` |
| AI Test modal fully restored (provider/model/context badges, callEditorAI) | `4aa769b` |
| AI dropdown buttons (Book Creator, Story Seed) fixed | `cd7db1a`, `a348832`, `7e07d0c`, `a141d05` |
| Help and Auto-save modals restored | `804486f` |
| Dropdown menus use targeted outside-click handlers (not global listeners) | `d8c04d4` |
| `fetchAIModels` uses browser fetch directly (OpenRouter, LM Studio, Ollama) | `0a25a92` |
| `console.error` → `console.warn` in supabase-runner proxy for missing server functions | `a674e8c` |
| `saveScheduleMilestonesAndCampaigns` function added | `52cb867` |

## Key Patterns & Conventions

- **Indentation**: 4 spaces in extracted modules
- **Include syntax**: `<?!= include('scripts/module-name'); %>` (no `.html` extension)
- **Build**: `node build.js` (recursive include processing, auto-strips BOM)
- **Output**: `build/Client.html` (~17,000+ lines inlined)
- **Element cache**: All `getElementById` calls go in `scripts/el-cache.html` under `window.el = {}`
- **Event bindings**: All DOM event wiring in `scripts/bind-events.html` in `bindEvents()`
- **State**: Global `appState` singleton in `scripts/app-state.html`
- **Line endings**: Client.html uses LF (git CRLF warnings are non-blocking)

## Common Gotchas

- Bootstrap sequence (last ~100 lines of Client.html) cannot be extracted before all functions it references are.
- New features should either: (a) add a new `scripts/<feature>.html` module + include + event binding, or (b) add inline to Client.html if tightly coupled with core flow.
- Build output is not committed — only source files matter.
- `sbClient` is `window.supabase.createClient(...)` using `window.__SUPABASE_URL__` and `window.__SUPABASE_ANON_KEY__` (injected at deploy time).

## Before New Development

```bash
node build.js    # Verify no include/parse errors
```

No test suite exists. Testing is manual via the running app.
