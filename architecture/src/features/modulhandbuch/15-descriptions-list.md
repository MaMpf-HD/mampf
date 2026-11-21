# Flows & Screens: Descriptions List

Find, filter and export `ModuleEdition`s; bulk status; clean up. **admin** all actions; **viewer** read, PDF, CSV.

---

## Flows

**L1. Find a description**
1. Descriptions → search "IAD" or "Algorithmen".
2. Default filter: newest term. Change to **all terms** to see every year (old Course list).

**L2. Filter**
- Combine: term, program / handbook, subject area, language, status, source, in handbooks, search.
- Status chips show counts for the current filters.
- **Reset filters** link.

**L3. See what changed since cloning** (replaces old Quelle filter)
- Filter **Source**:
  - *new*: no `cloned_from`
  - *copied unchanged*: copied, no printed field edited since
  - *edited since copy*: copied and edited
- Typical: after Prepare a term, "WS 2026/27 · edited since copy" = what needs review.

**L4. Choose columns** (replaces old Extra Feld 1–4)
1. **Columns ▾** → tick extra fields (lecturers, ECTS, LV‑Nr., cycle, responsible, last changed …).
2. Kept in the URL, so a shared link shows the same columns.

**L5. Export CSV**
- **CSV** → current filter and columns, all rows (not only the page).

**L6. Bulk status**
- Select rows → Set status ▾ created / checked / published (see [Review & Publish](14-review-and-publish.md)).

**L7. Clean up**
1. Filter **In handbooks: none** → descriptions no handbook lists anymore (e.g., ILat WS 2026/27).
2. Row ⋯ → **Delete**, or select → **Delete** (bulk). Asks once.
- Rows in a handbook have no Delete.

**L8. Open and step**
- Row click → edit page with ‹ n of N › over the current list.

---

## Screens

### S1. Descriptions list

```
Module descriptions                                     [Columns ▾] [CSV]

Search [__________]  Term [WS 2026/27 ▾]  Program [All ▾]  Subject [All ▾]
Language [All ▾]  Source [All ▾]  In handbooks [Any ▾]          Reset filters

Status: [created 40] [checked 3] [published 118] [all 161]

☐ Code   Name                                Term       Lang  Status       Used in  Last changed
☐ IACO   Applied Combinatorial Optimization  WS 26/27   en    ○ created    3        15.10. P.-Schmid
☐ IAD    Algorithmen und Datenstrukturen     WS 26/27   de    ● published  3        02.10. P.-Schmid
☐ ILat   Einführung in das Textsatzsystem …  WS 26/27   de    ○ created    0        copied
…                                                                         1 2 3 … ›
──────────────────────────────────────────────────────────────────────────────────
0 selected       [Set status ▾] [Delete]
```

- Row ⋯: Open, PDF, Delete (only "used in 0").
- "Used in" click → popover with the handbook names.

### S2. Columns popover

```
Columns
[✓] Code  [✓] Name  [✓] Term  [✓] Language  [✓] Status  [✓] Used in  [✓] Last changed
[ ] ECTS  [ ] LV-Nr.  [ ] Lecturers  [ ] Cycle  [ ] Responsible  [ ] Subject area
                                                            [Reset]
```

### S3. Delete dialog

```
Delete 2 descriptions?
  ILat · WS 2026/27
  IAML · WS 2026/27
They are in no handbook. This cannot be undone.
                                       [Cancel] [Delete]
```

### Viewer
S1 without checkboxes, bulk bar and Delete; Columns and CSV available.

---

## Small Decisions

1. Default term = newest term with handbooks; "all terms" is one click.
2. Filters and columns live in the URL (shareable, used by ‹ › on the edit page).
3. Bulk delete only for "in no handbook".
