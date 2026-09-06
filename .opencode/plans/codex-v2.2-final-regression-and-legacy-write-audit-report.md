# CODEX V2.2 — FINAL REGRESSION & LEGACY WRITE AUDIT REPORT

## 1. Executive Summary

```text
PASS — Codex v2 temporal state + relationship foundation can be frozen
```

- Automated temporal tests: **43/43 PASS**
- Existing test suite: **50/50 PASS**
- Build/syntax: **PASS**
- Legacy write audit: **1 potentially unsafe writer identified and documented**

---

## 2. Automated Temporal Relationship Tests

**File:** `tests/temporal-relationship.test.js`

**43 tests covering:**

| Category | Tests | Status |
|----------|-------|--------|
| Bounded same-book (B1 Ch3→B1 Ch8) | 6 | PASS |
| Cross-book (B1 Ch7→B2 Ch3) | 8 | PASS |
| Generic non-item (B1 Ch3→B2 Ch2) | 6 | PASS |
| NULL start | 4 | PASS |
| NULL end | 5 | PASS |
| NULL/NULL permanent | 4 | PASS |
| Ended status historical | 3 | PASS |
| Backwards/forwards determinism | 1 | PASS |
| Inverse direction | 2 | PASS |
| Future relationship no-leak | 4 | PASS |

**Canonical predicate tested:**
```
active if:
(valid_from_sort IS NULL OR valid_from_sort <= target_position)
AND
(valid_to_sort IS NULL OR valid_to_sort > target_position)
```

Start = inclusive, End = exclusive. All 43 assertions pass.

---

## 3. Existing Test Suite

```
Total tests: 50
Passed: 50
Failed: 0
```

All existing plan-outline-sync tests pass. No regressions.

---

## 4. Build/Syntax Check

```
Build: PASS
Syntax check: PASS (EXIT: 0)
```

---

## 5. Legacy/Non-Temporal Write Path Audit

### Complete Write Path Table

| # | Function | File | Caller(s) | UI/Feature | Relationship Types | Intentionally Permanent? | Safe? |
|---|----------|------|-----------|------------|-------------------|-------------------------|-------|
| 1 | `saveSkConnection` | series-knowledge.html:2007 | `skConnectionFormSaveButton` click | Connections tab in Series Knowledge sidebar | ANY (all types available) | NO — general purpose | **POTENTIALLY UNSAFE** |
| 2 | `saveEntityConnection` | series-knowledge.html:2457 | Relationship panel "+ Add" button | Right-column relationship panel | ANY | NO — temporal-capable | **SAFE** |
| 3 | `saveParentLocationConnection` | series-knowledge.html:2726 | Entity detail save (locations only) | Parent location selector | `located_in` only | YES — structural hierarchy | **SAFE** |
| 4 | `updateEntityConnectionType` | series-knowledge.html:2676 | Relationship panel edit | Right-column edit form | ANY (updates existing) | NO — temporal-capable | **SAFE** |
| 5 | Pilot `saveConnection` | codex-v2-dual-write.html:511 | `codexV2CreatePilotDataset` | Pilot data creation | `owns` | NO — temporal-capable | **SAFE** |

### Temporal-Capable Writers (for comparison)

| # | Function | Sends temporal fields? |
|---|----------|----------------------|
| 2 | `saveEntityConnection` | YES: `book_id`, `chapter_id`, `valid_from_sort`, `valid_to_sort`, `context_status`, `notes` |
| 4 | `updateEntityConnectionType` | YES: `book_id`, `chapter_id`, `valid_from_sort`, `valid_to_sort`, `context_status`, `notes` |
| 5 | Pilot `saveConnection` | YES: `book_id`, `valid_from_sort` |

---

## 6. Detailed `saveSkConnection` Audit

### Function Details
- **File:** `scripts/series-knowledge.html:2007-2046`
- **Payload:** `{id, source_entity_id, target_entity_id, relationship_type_id, description, label}`
- **Temporal fields sent:** NONE
- **Result:** Creates `valid_from_sort = NULL`, `valid_to_sort = NULL` (permanently active)

### Callers
1. `bindUiOnce(el.skConnectionFormSaveButton, "sk-conn-save", "click", saveSkConnection)` — `scripts/bind-events.html:1896`

### UI Exposure
- **Tab:** "Connections" in Series Knowledge sidebar
- **Form elements:** Source entity, Target entity, Relationship type, Description, Label
- **No temporal fields:** No book selector, no chapter selector, no valid from/until
- **Entity types that can access:** ALL entity types (the form is generic)
- **Relationship types allowed:** ALL (dropdown populated from `codex_relationship_types`)
- **User awareness:** The user is NOT told the relationship is permanent/unbounded

### Risk Assessment
- **Can it create temporal relationships (owns, member of, etc.) permanently?** YES
- **Is this intentional?** LIKELY NOT — this is a legacy form that predates temporal support
- **Is it safe as currently exposed?** POTENTIALLY UNSAFE — a user could create "Patrick owns Goblin Sword" through this form without temporal bounds, making it permanently active

### Recommended Fix (not implemented in this pass)
The cleanest fix would be to either:
1. Add optional temporal fields to this form (Valid From/Until Book+Chapter), OR
2. Route this form through the temporal-capable `saveEntityConnection` path, OR
3. Clearly label this form as "Permanent/Structural relationships only"

For this pass, the limitation is documented. The main relationship creation flow (right-column panel) is temporal-capable and is the recommended path.

---

## 7. Safe Legacy Writers

### `saveParentLocationConnection` (series-knowledge.html:2726)
- **Purpose:** Location hierarchy (parent location)
- **Relationship type:** `located_in` only
- **Temporal fields:** None (intentionally structural)
- **Why safe:** Location hierarchy is deliberately permanent/structural per spec: "It is acceptable for located_in parent hierarchy/breadcrumbs to remain structural for now."
- **UI:** Parent location selector in entity detail form
- **Does not imply temporal behaviour:** Correct

---

## 8. Existing NULL/NULL Data

**NOT INVESTIGATED** — this pass does not query the database for existing unbounded relationships. The spec says: "Do not mass-convert, delete, or guess dates for existing unbounded relationships."

If suspicious legacy rows exist, they should be reported separately with a deterministic migration rule.

---

## 9. State/Progression Regression

Existing state/progression behaviour confirmed intact:
- B1 Ch1 → Level 1, STR 6, Fireball No
- B1 Ch12 → Level 3, STR 8, Fireball Rank 1
- B2 Ch1 → Level 3, STR 8, Fireball Rank 1 (carry-forward)
- B2 Ch3 → Level 3, STR 10, Fireball Rank 1 (superseded)

No automated state tests were added in this pass (covered by manual live testing).

---

## 10. Active Relationships Verification

Active Relationships section added to:
1. **"View State At..."** (State tab) — queries `getActiveConnectionsAt` alongside state
2. **Progression Sheet** (Character tab) — queries both state and active relationships in parallel

Both use the same narrative position as the state query. Forward/inverse labels used correctly. Grouped by relationship label.

---

## 11. Files Changed

| File | Change |
|------|--------|
| `tests/temporal-relationship.test.js` | NEW — 43 automated temporal relationship tests |
| `scripts/series-knowledge.html` | Added Active Relationships to View State At and Progression Sheet |
| `.opencode/plans/codex-v2.2-active-relationships-contextual-view-report.md` | NEW — documentation |

---

## 12. Remaining Limitations

### Non-Blocking
- `saveSkConnection` legacy form creates NULL/NULL connections for any relationship type — documented as potentially unsafe
- No automated state/progression tests (manual only)
- No UI automation tests for temporal views

### Deferred
- Complex inventory UI
- Formula execution
- Separate temporal location hierarchy
- Major UI redesign for relationship panel
- `saveSkConnection` temporal fields addition

### Technical Debt
- `saveSkConnection` is a legacy path that should eventually be deprecated or upgraded
- No field definition/field value caching

---

## 13. Recommendation

```text
PASS — Codex v2 temporal state + relationship foundation can be frozen
```

**Rationale:**
1. All 43 temporal relationship tests pass
2. All 50 existing tests pass
3. Build/syntax clean
4. The only potentially unsafe writer (`saveSkConnection`) is a legacy form that should be documented/deprecated rather than fixed in this pass
5. The main relationship creation flow (right-column panel) is fully temporal-capable
6. Active Relationships contextual view is working
7. Manual live testing has verified cross-book temporal behavior

**Recommended follow-up (not blocking):**
- Add temporal fields to `saveSkConnection` or deprecate it
- Add automated state/progression tests
- Run Patrick pilot with real data to verify end-to-end
