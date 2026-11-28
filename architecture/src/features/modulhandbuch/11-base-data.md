# Flows & Screens: Base Data

`StudyProgram` and `CurriculumModule`.

---

## Flows

### CurriculumModule

**F1. Create a module**
1. Master data → Curriculum modules → **New module**.
2. Enter `code`, `title`, `subject_area`, `notes`.
3. Save → listed as active, "not used yet".
- `code` exists already → error on the field, with a link to the existing module.
- No `ModuleEdition` is created. That happens when the module is added to a `Handbook`.

**F1b. Create a module from the Handbook editor** (the common case)
1. Handbook editor → Add module → search "IARCA" → no result.
2. **Create module "IARCA"** → the same small form opens inline, code prefilled.
3. Save → module created and added right away ("Add empty").

**F2. Edit a module**
1. Open the module → edit `title`, `subject_area`, `notes`.
2. Used in any `Handbook` → banner: "Used in 14 terms. Title and subject area change everywhere; printed names are not affected."
- `code` is **not editable** once a `ModuleEdition` exists (public URLs, old handbooks). A real rename = new module (F5).

**F3. Deactivate / reactivate**
1. Open the module → **Deactivate** → "IAML will be hidden in Add module and skipped when cloning. Existing handbooks keep it."
2. Add a note, e.g., "ab SoSe 2026 nicht mehr im MHB".
- **Reactivate** reverses it (e.g., IAI came back in WS 2025/26).

**F4. Delete**
- Only without any `ModuleEdition` (typo, created by mistake).
- Otherwise disabled: "Has descriptions in 5 terms. Deactivate instead."

**F5. Rename** (old practice: new code)
1. Create the new module (F1), e.g., IOPSC.
2. Deactivate the old one (F3), e.g., IOPWR, note "umbenannt in IOPSC".
3. In the next term's handbooks, replace the old entry with the new one. "Copy from earlier term" can pick IOPWR's text as source.

### StudyProgram

**P1. Create a program** (new PO / new program)
1. Master data → Study programs → **New program**.
2. Enter `name`, `short_name`, `default_language`, `info`; `expires_on` empty.
3. Save → can be picked in New handbook / Prepare a term.

**P2. Edit**
- Change `name`, `info`, `default_language`. Existing handbooks keep their own `language`; only new ones use the new default.
- Changing `short_name` warns: public URLs change.

**P3. Expire** (PO runs out)
1. Set `expires_on`, e.g., 2026‑01‑01 for "Informatik BSc 100% alt".
2. After that date: not offered in New handbook / Prepare a term. Old handbooks stay readable and public.
- Clearing `expires_on` reactivates it.

**P4. New PO replaces old PO** (typical case)
1. Rename the old program to "… alt" and set `expires_on` (P2 + P3).
2. Create the new program with the plain name (P1).
3. New handbook for the new program → **clone from** the old program's last handbook.

**P5. Delete**
- Only without any `Handbook`. Otherwise: "Has 12 handbooks. Set an expire date instead."

### Term
- Not managed here: MaMpf's term management. If the target term for "Prepare a term" is missing, the dialog says so and links there.

---

## Screens

### S1. Master data, tab "Curriculum modules"

```
Master data   [Curriculum modules] [Study programs]

Search code / title [________]  Subject area [All ▾]  [✓] Active only      [+ New module]

Code     Title                              Subject area  Used in            Status
IACO     Applied Combinatorial Optimization Informatik    WS24/25 – WS26/27  active
IAML     Advanced Machine Learning          Informatik    WS15/16 – WS25/26  inactive
IARCA    Algorithmic Randomness and …       Informatik    not used yet       active
MA4      Lineare Algebra I                  Mathematik    WS13/14 – WS26/27  active
…                                                                    1 2 3 … ›
```

- Columns: code, title, subject area, used in (first – last term), status.
- Filters: search, subject area, active only (on by default).
- Row click → S2. Empty search → "No module 'XYZ'. [+ Create module XYZ]".

### S2. Curriculum module: detail / edit

```
IAML · Advanced Machine Learning                    [Deactivate] [Delete (disabled)]
⚠ Used in 22 terms. Title and subject area change everywhere; printed names not affected.

Code          IAML              (locked: has descriptions)
Title         [Advanced Machine Learning      ]
Subject area  [Informatik ▾]
Notes         [ab WS 2015/16 im MHB, ab SS 2026 nicht mehr im MHB ]
                                                         [Cancel] [Save]
Descriptions per term
  WS 2025/26  Advanced Machine Learning  en  published  BSc 100%, MSc DaCS   → open
  SS 2025     …
History  ▸
```

- "Descriptions per term": each `ModuleEdition` with name, language, status, handbooks. Replaces looking the module up in the old Course list over all semesters.
- Create: same form, empty, `code` editable; page or modal from S1 / Handbook editor.

### S3. Master data, tab "Study programs"

```
Master data   [Curriculum modules] [Study programs]

[✓] Hide expired                                                  [+ New program]

Name                            Short name           Lang  Expires     Handbooks
Informatik BSc 100%             Informatik BSc 100   de    —           12 · latest WS 26/27
Informatik BSc 100% alt         Informatik BSc 100…  de    2026-01-01  20 · latest WS 25/26
Informatik MSc Data and Comp…   Informatik MSc DaCS  en    —           11 · latest WS 26/27
```

- Columns: name, short name, language, expires, handbooks (count + latest term).
- Filter: hide expired (on by default). Row click → S4.

### S4. Study program: detail / edit

```
Informatik BSc 100% alt                                       [Delete (disabled)]
Expired since 2026-01-01: not offered for new terms.

Name              [Informatik BSc 100% alt              ]
Short name        [Informatik BSc 100 alt]   ⚠ used in public URLs
Default language  (•) de  ( ) en
Expires on        [2026-01-01]   [Clear]
Info              [MHB für den Bachelor 100% Angewandte Informatik nach der alten PO …]
                                                         [Cancel] [Save]
Handbooks
  WS 2025/26  published   → open
  SS 2025     published   → open
History  ▸
```

### Read-only view
For users without edit rights (who: see [Roles & Permissions](00c-roles-and-permissions.md)).

S1–S4 without buttons, all fields read‑only.

---

## Small Decisions

1. `code` locked once descriptions exist; rename = new module. Stricter than the old system (Code always editable).
2. Inline module creation from the Handbook editor (F1b).
3. Old "copy a Code" dropped. If staff use it for variants (IBa_100 → IBa_50), add **Duplicate** on S2.
