# Lifecycle Engine — Implementation Plan

## Phase 1: Read-Only Dashboard (No New Tables)

### Goal
Add a LIFECYCLE Studio tab that calculates current stage, progress, blockers, and next actions from existing data. Zero schema changes. Zero new Supabase tables.

---

### Tab Position
```
PROJECTS | LIFECYCLE | CHAT | PLAN | WRITING | CODEX | PUBLISHING | MARKETING | RESOURCES
```

---

### Files to Modify

| File | Change |
|---|---|
| `Index.html` | Add tab button + content container |
| `scripts/el-cache.html` | Cache new DOM elements |
| `scripts/bind-events.html` | Add click handler |
| `Client.html` | `switchMainTab()` whitelist + init block, `selectProject()` hook |
| `scripts/app-state.html` | Add `lifecycle` state property |
| `Styles.html` | Lifecycle tab styles |

### New File
| File | Purpose |
|---|---|
| `scripts/lifecycle.html` | All lifecycle calculation + rendering logic |

---

### Step 1: Tab Registration

**Index.html** — Add button after line 441 (after PROJECTS):
```html
<button id="mainTabLifecycle" class="main-tab" type="button" data-main-tab="lifecycle">LIFECYCLE</button>
```

**Index.html** — Add content container after `mainTabContentWriting` closes (after line ~551):
```html
<div id="mainTabContentLifecycle" class="main-tab-content" hidden>
  <div id="lifecycleContainer"></div>
</div>
```

**scripts/el-cache.html** — Add after `mainTabContentChat`:
```javascript
mainTabLifecycle: document.getElementById("mainTabLifecycle"),
mainTabContentLifecycle: document.getElementById("mainTabContentLifecycle"),
```

**scripts/bind-events.html** — Add `el.mainTabLifecycle` to the tab button array on line 2.

---

### Step 2: switchMainTab() Integration

**Client.html line 6138** — Add `"lifecycle"` to whitelist:
```javascript
["writing", "lifecycle", "plan", "workspace", "publishing", "marketing", "resources", "codex", "chat"]
```

**Client.html line 6146** — Add `el.mainTabLifecycle` to button toggle array.

**Client.html line 6150** — Add `el.mainTabContentLifecycle` to content toggle array.

**Client.html after line 6167** — Add panel visibility:
```javascript
// Lifecycle uses the project inspector panel (same as PROJECTS)
if (el.projectInspectorPanel) el.projectInspectorPanel.hidden = (safeTab === "resources" || safeTab === "codex" || safeTab === "workspace" || safeTab === "plan" || safeTab === "chat");
```
(No change needed — lifecycle should show the project inspector, which is already visible for tabs not in the exclusion list.)

**Client.html after line 6252** — Add init block:
```javascript
if (safeTab === "lifecycle") {
  renderLifecycleDashboard();
}
```

---

### Step 3: selectProject() Hook

**Client.html after line 3016** — Add:
```javascript
if (activeMainTab === "lifecycle") {
  renderLifecycleDashboard();
}
```

---

### Step 4: appState

**scripts/app-state.html** — Add after `chatContext`:
```javascript
lifecycle: {
  lastCalculated: null,
  currentPhase: "",
  currentStage: "",
  progressPct: 0,
  blockers: [],
  nextActions: [],
  stageChecklist: [],
  communicationQueue: []
}
```

---

### Step 5: Lifecycle Calculation Engine

**New file: `scripts/lifecycle.html`**

#### Stage Derivation from project.status

```javascript
var LIFECYCLE_STAGES = [
  { key: "story_seed",    label: "Story Seed",      requiredStatuses: ["Idea"] },
  { key: "project",       label: "Project",          requiredStatuses: ["Idea", "Writing", "Draft", "Editing", "Publish Ready", "Published"] },
  { key: "validation",    label: "Validation",       requires: "hasSummary" },
  { key: "research",      label: "Research",         requires: "hasCodexEntries" },
  { key: "codex",         label: "Codex",            requires: "hasCodexEntries" },
  { key: "planning",      label: "Planning",         requires: "hasOutline" },
  { key: "draft_prep",    label: "Draft Preparation", requires: "hasOutline" },
  { key: "first_draft",   label: "First Draft",      requiredStatuses: ["Writing", "Draft"] },
  { key: "revision",      label: "Revision",         requiredStatuses: ["Draft", "Editing"] },
  { key: "development_edit", label: "Development Edit", requiredStatuses: ["Editing"] },
  { key: "serial_prep",   label: "Serial Preparation", requires: "hasPublishDate" },
  { key: "publication",   label: "Publication",      requiredStatuses: ["Publish Ready", "Published"] },
  { key: "evergreen",     label: "Evergreen",        requiredStatuses: ["Published"] }
];
```

#### Calculation Functions

Each function reads from existing appState — no Supabase calls:

```javascript
function calculateLifecycleStage(project)
  // Maps project.status to the furthest completed stage
  // Checks outline existence (appState.writingWorkspace.outline)
  // Checks codex entries (codexCache or skCache)
  // Checks word count (document_sections aggregate)
  // Checks publish_date existence
  // Checks campaigns existence

function calculateProgress(project)
  // Returns 0-100 based on completed stages / total stages

function calculateBlockers(project)
  // Returns array of { reason, source } objects
  // Examples:
  //   - "Draft incomplete" (word count < target from outline)
  //   - "No publish date set"
  //   - "Cover image missing"
  //   - "No campaigns configured"

function calculateNextActions(project)
  // Returns array of { action, module, urgency } objects
  // Examples:
  //   - { action: "Complete outline", module: "plan", urgency: "high" }
  //   - { action: "Add codex entries", module: "codex", urgency: "medium" }
  //   - { action: "Set publish date", module: "publishing", urgency: "low" }
```

#### Data Sources (all from appState — no new fetches)

| Calculation | Reads From |
|---|---|
| Status → stage mapping | `project.status` |
| Has outline | `appState.writingWorkspace.outline` or `project.outline` |
| Has chapters | `appState.writingWorkspace.segments` |
| Word count | Sum of `document_sections` word_count (already cached) |
| Has codex | `codexCache.entitiesBySeries[seriesId]` or `skCache` |
| Has publish date | `project.publish_date` |
| Has campaigns | `project.campaigns` |
| Has milestones | `project.schedule_milestones` |
| Has cover image | `project.image` |

---

### Step 6: UI Rendering

**renderLifecycleDashboard()** renders into `#lifecycleContainer`:

```
┌─────────────────────────────────────────────────────────────┐
│  CURRENT POSITION                                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Phase: Production          Stage: First Draft           ││
│  │ Progress: ████████░░░░░░░░░░░░ 42%                     ││
│  │ Est. Completion: 2026-08-15                             ││
│  │ Next Action: Write Chapter 7 (PLAN)                     ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  STAGE CHECKLIST                                            │
│  ┌─────────────────────────────────────────────────────────┐│
│  │ ✓ Story Seed                                            ││
│  │ ✓ Project                                               ││
│  │ ✓ Validation                                            ││
│  │ ✓ Research                                              ││
│  │ ✓ Codex                                                 ││
│  │ ✓ Planning                                              ││
│  │ ✓ Draft Preparation                                     ││
│  │ → First Draft                           ← current       ││
│  │ ○ Revision                                              ││
│  │ ○ Development Edit                                      ││
│  │ ○ Serial Preparation                                    ││
│  │ ○ Publication                                           ││
│  │ ○ Evergreen                                             ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  BLOCKERS                              COMMUNICATION QUEUE  │
│  ┌────────────────────────────┐  ┌────────────────────────┐ │
│  │ ⚠ Draft incomplete         │  │ ○ Draft Newsletter     │ │
│  │   12,400 / 60,000 words    │  │ ○ Draft Patreon Post   │ │
│  │ ⚠ No cover image           │  │ ○ Draft Launch Email   │ │
│  │ ○ Publish date set          │  │ ○ Draft Social Campaign│ │
│  └────────────────────────────┘  └────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

### Step 7: Styles

Add to `Styles.html`:

```css
/* Lifecycle Tab */
.lifecycle-container { padding: 24px; max-width: 960px; margin: 0 auto; }
.lifecycle-position { ... }
.lifecycle-stage { ... }
.lifecycle-progress-bar { ... }
.lifecycle-blockers { ... }
.lifecycle-comms-queue { ... }
```

---

### Step 8: Include Script

**Client.html** — Add to the script includes block:
```html
<?!= include('scripts/lifecycle'); ?>
```

---

## Phase 1 Deliverables

- [x] LIFECYCLE tab button in Studio bar
- [x] Content container with dashboard layout
- [x] `renderLifecycleDashboard()` function
- [x] Stage calculation from `project.status` + existing data
- [x] Progress percentage
- [x] Blocker detection
- [x] Next action suggestions
- [x] Stage checklist with current position marker
- [x] Communication queue (read-only list of what needs drafting)
- [x] Refreshes on `selectProject()` and tab switch
- [x] No new Supabase tables
- [x] No schema changes

---

## Phase 2+ (Future)

Phase 2: `lifecycle_templates` + `lifecycle_template_stages` + `project_lifecycles` + `project_stage_status` tables. Approval gates. Custom workflows.

Phase 3: Communication drafting. LLM-generated drafts stored as `document_sections` with `doc_type="lifecycle_comms"`. Human review flow.

Phase 4: Automation. Scheduled reminders. Campaign package generation. Dashboard summaries.

Phase 5: Analytics. Capacity planning. Publishing forecasts. Studio reporting.
