# Flows & Screens: Review & Publish

Publishing is a **status flag**, nothing more. There are two independent flags:

| Flag | On | Values | Means |
|---|---|---|---|
| Description status | `ModuleEdition.status` | `created` / `checked` / `published` | How far the text is. Only `published` descriptions appear in the official PDF and on public pages. |
| Handbook status | `Handbook.status` | `draft` / `published` | "This handbook is online." Read‑only users and public pages see only `published` handbooks. |

```admonish info "Release is a separate right"
The description status is a manual flag; nothing changes it automatically, and saving keeps the status.
- `created` / `checked`: anyone who may edit the description.
- `published` (Freigabe), set or remove: only with the **release right**.
- Any transition is allowed within those rights (e.g., `created` → `published`).

Who has which right: [Roles & Permissions](00c-roles-and-permissions.md). An enforced workflow (fixed order, reset on edit) is in [Future Extensions](09-future-extensions.md#enforced-review-workflow).
```

```admonish warning "⚑ Open: what does `checked` change?"
So far `checked` only affects export and views; it is not yet clear how. Candidates: a draft export of "checked + published", a status filter / chip in the lists. **TODO: ask the staff.** Until then, `checked` is a progress marker only.
```

---

## Flows

### Description status (`ModuleEdition`)

**R1. Set the status of one description**
- Edit page → status control (S4) → choose `created` or `checked`, or `published` (release right only).
- Without the release right, `published` is disabled ("Needs release right").
- Setting `published` or leaving it: if the description is in a published handbook, the confirmation says so ("IAD appears in / disappears from the official PDF of BSc 100%").

**R2. Set the status in bulk**
1. Descriptions list → filter by status (e.g., chip "created 40").
2. Select rows (or all) → **Set status ▾** → `created` / `checked` / `published` (bulk bar; `published` with release right only).
   - Typical release: filter **checked** → select all → **published**.
3. Dialog (S2): "Publish 37 descriptions? 12 are used in published handbooks and appear there now." → confirm.

**R3. Edit a published description**
- **Save** keeps the status. The change is live at once in every handbook that lists it.
- The save names the handbooks that use it ("Used in: MSc Mathematik, MSc DaCS"), so the reach of the change is visible.

### Handbook status (`Handbook`)

**R4. Publish a handbook**
1. Handbook editor → **Publish**.
2. Dialog (S3):
   - `issue_date` empty → "Set the issue date first" (blocks).
   - Descriptions not `published` → "3 descriptions are not published and will be missing from the official PDF: IPK, IITS3, MLat." → **Publish anyway** / **Go to descriptions**.
3. Status `published`, `published_at` set. Read‑only users and public pages see it.

**R5. Unpublish a handbook**
- Editor → ⋯ → **Unpublish** → "Removes BSc 100% WS 2026/27 from public pages." → confirm → `draft`.

**R6. Publish the whole term** (shortcut)
- Handbooks list → filter term → select → **Publish** → same checks as R4, per handbook; the result lists the blocked ones.

---

## Screens

### S1. Status in the Descriptions list

```
Term [WS 2026/27 ▾]   Status: [created 40] [checked 3] [published 118] [all]

☐  Code   Name                               Lang Status       Used in
☑  IAD    Algorithmen und Datenstrukturen    de   ◐ checked    3
☑  IACO   Applied Combinatorial Optimization en   ○ created    3
…
─────────────────────────────────────────────────────────────────────
2 selected        [Set status ▾]
```

### S2. Bulk status dialog

```
Publish 37 descriptions?
  · 12 are used in published handbooks and appear there now.
                                              [Cancel] [Publish 37]
```

### S3. Publish handbook dialog

```
Publish Informatik BSc 100% · WS 2026/27?
✓ Issue date: 15.10.2026
⚠ 3 descriptions are not published; they will be missing from the official PDF:
    ○ IPK   Programmierkurs
    ○ IITS3 IT-Sicherheit 3
    ◐ MLat  Introduction to LaTeX
                          [Go to descriptions] [Cancel] [Publish anyway]
```

### S4. Status control on the description edit page

```
Status  ( ○ created | ◐ checked | ● published )
```

`● published` is only clickable with the release right; otherwise disabled.

Disabled while there are unsaved changes ("Save first").

---

## Small Decisions

1. Three statuses (`created` / `checked` / `published`), set by hand. `created` / `checked` by anyone who may edit; `published` only with the release right.
2. Saving never changes the status. History records who changed what.
3. `issue_date` must be set before publishing a handbook (old: the "Datum muss noch aktualisiert werden!" note was easy to forget).
4. Unpublished descriptions do not block handbook publishing; they are listed and left out.
5. Bulk publish of a whole term's handbooks (R6) for the semester start.
