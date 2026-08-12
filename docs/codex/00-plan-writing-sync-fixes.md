# Plan Tab ↔ Writing Tab Chapter Sync — Audit & Fix Plan

Audit date: 2026-08-12
Status: Phase 1 in progress

## Summary

The Plan tab and Writing tab share two in-memory objects on `appState.writingWorkspace`:
- `outline` — canonical structure `{ acts:[{children:[{type:"chapter", id, title, sortOrder, children:[scenes]} ]}], brainstorming, characterArcs, worldBuilding }`, persisted as a single full-JSONB `projects.outline` write (`savePlanOutline` → `saveSupabaseProjectOutlineJsonFromClient`, `scripts/supabase-crud.html:94`).
- `segments` — the Writing-tab chapter list, keyed by chapter id, body text persisted per-row in `document_sections` (`doc_type='draft'`, upsert on `project_id, doc_type, section_key`).

The bridge is `syncOutlineToSegments()` (`scripts/plan-outline.html:126`): every structural plan edit rebuilds `segments` from outline chapters, preserving text only when `segment.key === chapter.id`.

**The identity contract — `segment.key === chapter.id` — is the single point of failure.**

## Audit findings (verified against source, 2026-08-12)

### Data loss

- **L1 — Project-switch race overwrites the newly-selected project with empty draft/outline.**
  `selectProject` (`Client.html:3006`) clears segments/outline/snapshots (3060-3065) but never cancels pending save timers — `saveManager.cancel()` (`scripts/save-manager.html:143`) has zero call sites. Debounce timers (`workspace` 1800ms, `planOutline` 3000ms) and the 300s interval tick fire after the switch, re-read `getSelectedProject()` (= project B) and find empty state → `saveWritingWorkspaceDraft` writes `[]` and `savePlanOutline` full-overwrites B's `projects.outline` with `{}`.
- **L2 — `syncOutlineToSegments` drops any writing chapter not present in the outline.** plan-outline.html:136-148 rebuilds segments only from outline chapters; a segment whose key isn't an outline id (legacy `chapter-N`, `segment-N`, or a writing-tab-created chapter) is removed from `segments`. The next draft save omits those keys → rows orphaned → `cleanupOrphanedSections` (`Client.html:5472`) can permanently delete them.
- **L3 — Plan textareas (brainstorming/characterArcs/worldBuilding) have no autosave.** No `input`/`change` listener exists; content is captured only by `syncPlanTextareasToOutline` (`Client.html:5520`) inside `savePlanOutline`, which fires only on plan structural edits, manual Save, or writing-tab saves. Typing only in a textarea then switching tabs/projects/closing loses the text. `populatePlanTextareas` (`Client.html:4943`) resets the textarea from stale in-memory outline on workspace load, erasing unsaved text. **Resolved as N/A (2026-08-12): the referenced textareas are legacy — they have no DOM elements (`el-cache.html` never caches them, `Index.html` Plan tab contains only the outline grid). All textarea refs were dead no-ops. Removed `populatePlanTextareas`, `syncPlanTextareasToOutline`, and `renderPlanBrainstorm/CharacterArcs/WorldBuild`; `brainstorming`/`characterArcs`/`worldBuilding` remain in the outline data model and are still round-tripped through the outline JSONB.**
- **L4 — Concurrent outline saves can finish out of order (older snapshot wins).** `savePlanOutline`'s dedup guard reads `outlineSnapshot` at entry (5544) and updates it only on success (5551). `saveWritingWorkspaceDraft` calls it directly (5437), bypassing `saveManager` per-area serialization. Two overlapping saves can both pass the guard; the older request completing last wins.
- **L5 — Offline retry silently drops payloads.** `_processOfflineQueue` (`scripts/save-manager.html:197-203`) only restores a queued payload when the area has no newer pending save, otherwise it is discarded.
- **L6 — `flushCurrentWorkspaceEdits` inside `selectProject` writes A's notes/fixes into B.** `selectProject` sets `selectedRowNumber = B` (3014) then flushes (3059); `saveWritingWorkspaceNote/Fix` (`Client.html:4767/4779`) resolve the project via `getSelectedProject()` (= B), upserting A's note text under A's chapter keys into B.

### Distortion

- **D1 — `renumberOutlineChapters` auto-renumbers user titles.** plan-outline.html:117-121 rewrites any title matching `/^(Chapter\s+)(\d+)(\s*:\s*.*)?$/i` to the new global position on every sync. Reordering silently renumbers "Chapter 12: The Finale". Writing side normalizes the same way via `parseDraftChapterTitleParts`/`buildDraftChapterLabel` (`Client.html:904-923`).
- **D2 — Scene field mismatch `pov` vs `povType`.** `addPlanScene` (plan-outline.html:216) writes `pov:""`; renderer reads `scene.povType` (632).
- **D3 — Dormant writing-tab chapter functions are data-loss capable.** `createWritingWorkspaceNewChapter`/`deleteWritingWorkspaceChapter`/`moveWritingWorkspaceChapter`/`renumberWritingWorkspaceSections` (`Client.html:5231/5264/5306/4609`) rewrite all keys to positional `chapter-N` (4616-4617) and set fabricated scopes (5321); following `syncOutlineToSegments` can't match keys → segment text resets to `<div><br></div>`. Buttons removed (`scripts/el-cache.html:617`) but functions remain.

### Staleness / conflict

- **S1 — No cross-tab/device sync; last-write-wins clobbers remote edits.** No `storage`/`BroadcastChannel`/`visibilitychange` listener. `loadPlanData` (`Client.html:3094`) and `loadWritingWorkspaceDraft` (4879) never refetch for an already-loaded project.
- **S2 — `loadPlanData` never sets `outlineSnapshot`/chapter states** (`Client.html:3091-3114`). First `savePlanOutline` re-writes unchanged outline; every chapter shows an "Unsaved" dot until the first save.
- **S3 — `loadPlanData` has no stale-result guard → cross-project outline pollution.** Its async `.then` assigns `writingWorkspace.outline` unconditionally (3104); `selectProject` never bumps `writingWorkspace.version` itself.
- **S4 — Backup restore can downgrade server data.** `loadWritingWorkspaceDraft` catch path (4974-4981) prefers the localStorage backup's outline; the backup (`backupWorkspaceToLocalStorage`, 5179-5186) excludes notes/fixes and `outlineSnapshot`.

### UI consistency

- **U1** Chapter numbers disagree across surfaces (plan global position, writing sidebar outline order, scope dropdown/editor array index).
- **U2** `switchMainTab` (`Client.html:6294`) doesn't call `renderPlanOutline()` on entering Plan.
- **U3** `schedulePlanOutlineSave`/`scheduleWritingWorkspaceAutoSave` silently no-op when the area is disabled (`scripts/save-manager.html:114`, `Client.html:5508`) with no fallback.
- **U4** `deletePlanNode`/`deleteAllPlanOutline` leave `savedOutlineChapterStates`/`savedSegmentTexts` stale.

## Fix plan (phased)

### Phase 1 — Stop data loss (in progress)

- **P1.1 Project-bound save token + cancel on switch.**
  - Add `saveManager.cancelAll()`; call it at the top of `selectProject`'s `!isSameProject` block.
  - Capture `saveProjectId` in `saveWritingWorkspaceDraft` and `savePlanOutline`; bail out of state mutation/render if the selected project changed before the async continuation runs.
  - Fix L6: pass a captured `projectId` into `saveWritingWorkspaceNote`/`saveWritingWorkspaceFix` from `flushCurrentWorkspaceEdits`.
  - **Flush-before-cancel (2026-08-12):** `cancelAll()` alone was destroying pending edits — it cleared the `planOutline`/`workspace` debounce timers before the edit was ever written, so a plan detail edited within 3s of a project switch was lost. `selectProject` now runs `flushCurrentWorkspaceEdits(prev)` + `saveWritingWorkspaceDraft({autosave:true})` + `savePlanOutline()` **before** `appState.selectedRowNumber` changes (while A is still selected), then `cancelAll()`.
  - **Call-time capture in `savePlanOutline`:** the `_outlineSaveChain` defers execution, so `executePlanOutlineSave` used to re-read `getSelectedProject()` at execution time (after the switch → would capture B). `savePlanOutline` now captures `saveProjectId` + `outline` snapshot at call time; `executePlanOutlineSave(saveProjectId, snapshot)` writes that captured snapshot and only mutates UI state when `stillCurrent()`.
  - **S2 pulled into Phase 1 (2026-08-12):** after a project switch, the Plan-tab load path (`loadPlanData`, `Client.html:3097`) never set `outlineSnapshot`/`savedOutlineChapterStates`, so the just-fetched (saved) outline rendered with orange "Unsaved" dots until a manual save re-baselined. `loadPlanData` now sets `outlineSnapshot` + `snapshotOutlineChapterStates()` after load and got the version guard; `selectProject` bumps `appState.writingWorkspace.version` on switch so in-flight stale fetches bail.
- **P1.2 Serialize outline writes.** Module-level `_outlineSaveChain` in `Client.html`; every `savePlanOutline` chained so no two writes overlap.
- **P1.3 Disabled-area fallback.** If `sm.schedule(...)` returns `false`, fall through to the `setTimeout` fallback instead of returning silently.
- **P1.4 Plan textarea autosave.** **Cancelled (N/A, 2026-08-12):** the plan textareas are legacy elements with no DOM presence (see L3); dead wiring removed. The `beforeunload` best-effort `saveImmediate("planOutline")` was still folded into the P1.1/P1.2 verification.

### Phase 2 — Single identity model (deferred)

- Remove/deprecate dormant writing-chapter key rewrites (`renumberWritingWorkspaceSections` etc.).
- One-time legacy key reconciler: `chapter-N` → `ol-*` by position. **Decision: auto-merge when safe, skip when ambiguous** (only when counts match and ordering is consistent; otherwise leave rows and flag).
- `syncOutlineToSegments` preserves unknown segments instead of dropping.
- Stop auto-renumbering user titles (display number at render time only).

### Phase 3 — Conflict detection (deferred)

- `updated_at` optimistic concurrency on `projects.outline` (+ lighter on `document_sections`).
- Cross-tab invalidation via `storage` listener / `BroadcastChannel`.
- `loadPlanData` sets `outlineSnapshot`/chapter states and gets the version guard; bump `version` in `selectProject`. **Done in Phase 1 (2026-08-12).**
- Safer offline queue (`_processOfflineQueue` re-enqueues even with pending); include notes/fixes/`outlineSnapshot` in the localStorage backup.

### Phase 4 — Cleanup & consistency (deferred)

- Safe `cleanupOrphanedSections` gated behind Phase 2 migration, with preview.
- Stale-map hygiene on delete.
- Unified chapter numbering helper.
- `switchMainTab` re-renders Plan on entry.
- Scene POV normalization.

## Implementation notes

- Source of truth: `Client.html`, `scripts/*.html`. `build/` is generated via `npm run build` for Vercel; dev server serves source directly.
