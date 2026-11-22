# Flows & Screens: Description Editing

Edit one `ModuleEdition` (one module in one term).

---

## Flows

**D1. Open a description**
- From the Handbook editor: click a row → side panel (S2) → **Open full page** if needed.
- From the Descriptions list: click a row → edit page (S1).
- From a module's detail (Base data S2): "Descriptions per term" → open.

**D2. Edit and save** (status `created`)
1. Change fields: `language`, `name`, `lv_number`, `ects`, text fields, `responsible_user_id`, `internal_remarks`.
2. **Save** → saved, status stays `created`.

**D3. Edit and save** (status `checked` / `published`)
1. Change fields.
2. **Save** → status stays as it is. If `published`, dialog (S3): "IACO WS 2026/27 is published. The change is live in: MSc Mathematik, MSc DaCS, MSc SciComp." → **Save** / Cancel.
- Only internal fields (`internal_remarks`, `responsible_user_id`) changed → saved without dialog.
- The status is changed separately with the status control (see [Review & Publish](14-review-and-publish.md) S4).

**D4. Compare with previous term**
1. Toggle **Compare with SoSe 2026** (the `cloned_from`).
2. Each field shows a word diff: added green, removed red; unchanged fields collapsed.
- Language changed since the previous term → no diff; the previous text is shown next to the current one.
- No `cloned_from` (new module) → toggle hidden.

**D5. Step through a list**
1. Opened from a filtered list (e.g., "WS 2026/27 · created") → header shows **‹ 3 of 12 ›**.
2. ‹ › opens the previous / next one with the same filter. Unsaved changes → "Save / Discard / Stay".

**D6. Preview and PDF**
- **Preview** tab: the module page as printed (labels in the language of the handbook opened from, or the `ModuleEdition`'s language).
- **PDF**: single module PDF (see [Export](17-export.md)).

**D7. Change the language**
1. Switch `language` de → en.
2. Hint: "Translate name and text fields; the handbook prints them as entered." Nothing is translated automatically.

**D8. See who changed it**
- **History** panel at the bottom (see [History](18-history.md)).

---

## Screens

### S1. Description edit page

```
IACO · WS 2026/27 · ○ created              ‹ 3 of 12 ›     [Preview] [PDF] [Compare ☐]
Used in 3 handbooks: MSc Mathematik, MSc DaCS, MSc SciComp

Language        (•) en  ( ) de
Name            [Applied Combinatorial Optimization        ]
LV-Nr.          [1300282205]       ECTS [8]
Lecturers       [Bogdan Savchynskyy                        ]
Duration        [one semester]     Cycle [every winter semester]
Format          [Lecture 4 SWS + Exercise course 2 SWS     ]
Workload        [240 h; thereof 60 h lectures …            ]
Usability       [M.Sc. Data and Computer Science …         ]
Exam scheme     [1+1]
Learning goals  [The students                               ]
                [- can analyze combinatorial optimization … ]
Topics          [The course is devoted to …                 ]
Prerequisites   [recommended: Linear Algebra, Analysis …    ]
Exam modalities [                                           ]
Credit award    [The module is completed with a graded oral …]
Literature      [Savchynskyy, Bogdan. Discrete graphical …  ]
── internal ──────────────────────────────────────────────
Responsible     [Savchynskyy, Bogdan ▾]
Remarks         [                                           ]
Status  ( ○ created | ◐ checked | ● published )         [Cancel] [Save]
History ▸
```

- Status buttons (see [Review & Publish](14-review-and-publish.md)) are disabled while there are unsaved changes.
- Text fields grow with content; lists and simple tables allowed.

### S2. Side panel (from the Handbook editor)

```
┌ IACO · WS 2026/27 · ○ created                    [Open full page] ✕ ┐
│ Used in 3 handbooks                                                 │
│ Name, Language, ECTS, LV-Nr. (editable)                             │
│ Text fields collapsed: Learning goals ▸ Topics ▸ …                  │
│                                                  [Save]             │
└─────────────────────────────────────────────────────────────────────┘
```

- For quick fixes without leaving the editor. Same save rules (S3).

### S3. Save dialog (published description)

```
Save changes to IACO WS 2026/27?
It is ● published; the change is live at once in:
  · Mathematik MSc · WS 2026/27 (published)
  · Informatik MSc DaCS · WS 2026/27 (draft)
  · SciComp MSc · WS 2026/27 (draft)
                                           [Cancel] [Save]
```

The status stays ● published. To take it out of the official PDFs, set the status separately.

### S4. Compare view (field level)

```
Literature                                         compared with SoSe 2026
  Savchynskyy, Bogdan. Discrete graphical models …
- Korte, Bernhard H. Combinatorial optimization. Berlin: Springer, 2008.
+ Korte, Bernhard H. Combinatorial optimization. Berlin: Springer, 2011.
  Beck, Amir. First-order methods in optimization …
Topics                                             unchanged ▸
```

### Read-only view
For users without edit rights (who: see [Roles & Permissions](00c-roles-and-permissions.md)).

S1 read‑only: no Save, no status buttons, internal section hidden.

---

## Small Decisions

1. No "New description" button anywhere; descriptions come from a handbook or cloning.
2. Side panel for quick edits plus full page for long edits / review.
3. Internal fields (`responsible_user_id`, `internal_remarks`) are hidden in the read‑only view.
