# Base Data: Study Programs, Curriculum Modules, Terms

```admonish question "What is 'Base data'?"
The verified, term‑independent master data (Stammdaten) of the handbook: `StudyProgram`, `CurriculumModule`, and `Term` (from MaMpf).

- **Common Examples:**
  * `StudyProgram`: "Informatik BSc 100%", "Informatik BSc 100% alt"
  * `CurriculumModule`: "IAD", "MA4"
  * `Term`: "WS 2026/27"
- Records that **are the same in every term**. Everything that can differ per term lives on [`ModuleEdition`](03-module-editions.md).
```

| Model | New? | Old system |
|-------|------|------------|
| `Handbook::StudyProgram` | new | Modulhandbuch (Liste / Edit) |
| `Handbook::CurriculumModule` | new | Code (Course → Code, StudDekanin → CodeList) |
| `Term` | **reused from MaMpf** | Semester |

## Problem Overview

- MaMpf `Course`/`Lecture` records are created by teachers and are not verified, so they cannot be the source of an official document.
- A study program exists in variants: degree, share, **and PO version** ("Informatik BSc 100%" vs. "Informatik BSc 100% alt", "Informatik Lehramt", "MSc DaCS"). Each variant has its own handbook.
- A module's printed name can change over time. Changing it must not rewrite handbooks of earlier terms.

## Solution Architecture

- **`StudyProgram` as plain records** with name, short name, default language and expire date. No degree/share enums: the old data (Lehramt, alt PO, DaCS, MLDS) does not fit them, and nothing uses them.
- **One `CurriculumModule` per module code.** It holds the identity (code, subject area, notes), not the printed name. The printed name lives on `ModuleEdition`, in that `ModuleEdition`'s language.
- **`Term` reused from MaMpf**, no new table.

---

## Handbook::StudyProgram (ActiveRecord Model)

```admonish info "What it represents"
A study program variant (program + PO version) for which handbooks are written.
```

```admonish tip "Think of it as"
The cover page of a handbook: "Modulhandbuch Informatik BSc 100%".
```

| Name/Field | Type/Kind | Description |
|------------|-----------|-------------|
| `name` | DB column | Full name (e.g., "Informatik BSc 100%") |
| `short_name` | DB column | Short name, unique (e.g., "Informatik BSc 100"); used in URLs |
| `default_language` | DB column (Enum) | `de`, `en`; default language of its handbooks |
| `expires_on` | DB column, nullable | After this date the program is not offered for new terms (old PO) |
| `info` | DB column | Free text (PO date, notes) |
| `handbooks` | Association | All handbooks of this program, one per term |
| `active?` | Method | `expires_on` nil or in the future |

### Behavior Highlights

- `short_name` is unique.
- Cannot be destroyed while a `Handbook` references it (`dependent: :restrict_with_error`).
- Expired programs are hidden in "Prepare a term" and in the new‑handbook form. Their handbooks stay readable.
- One name only: English programs (DaCS, MLDS) already have English names. The handbook language comes from `default_language`, not from the name.

---

## Handbook::CurriculumModule (ActiveRecord Model)

```admonish info "What it represents"
A verified module code, independent of any term.
```

```admonish tip "Think of it as"
- "IAD" as an entry in the examination regulations, not the lecture that Prof. X gives in WS 2026/27.
- A verified version of `Lecture` in MaMpf
```

| Name/Field | Type/Kind | Description |
|------------|-----------|-------------|
| `code` | DB column | Unique module code (e.g., "IAD", "MA4") |
| `title` | DB column | Internal label for search and lists (e.g., "Algorithmen und Datenstrukturen") |
| `subject_area` | DB column (Enum) | `math`, `cs`, `general` (old Fachgebiet: Mathematik, Informatik, Allgemeine Module) |
| `notes` | DB column | Free text (old `Info`: "ab WS 2020/21 im MHB", "Umbenennung von …") |
| `active` | DB column (Boolean) | `false` = no longer offered; hidden in "Add module" |
| `module_editions` | Association | All `ModuleEdition`s of this module, one per term |
| `edition_for(term)` | Method | The `ModuleEdition` in a given term, or `nil` |

```admonish note "Printed name on `ModuleEdition`"
The printed name (`name`) lives on `ModuleEdition`, in its language, and is copied to the next term on clone. Renaming only changes that term and later clones; published handbooks of earlier terms keep their name. This matches the old system: Code has no name, Modulbezeichnung is per semester.
```

### Behavior Highlights

- `code` is required and unique. Old codes differ only by case in some places (`IIug_alt` / `IIuG_alt`, `IBa_100_neu` / `IBA_100_neu`), contain spaces (`MA6 IPR`) or umlauts (`ISWÖk`): uniqueness is case‑sensitive, and URLs must escape the code.
- Cannot be destroyed while a `ModuleEdition` exists. Use `active: false` instead.
- Creating a `CurriculumModule` does **not** create a `ModuleEdition`.
- A real rename in the old system usually got a **new code** (IOPWR → IOPSC, ISWÖk → ISWEco) with a note in both. Keep that practice; optional later: `replaced_by_id`.
- Program variants of one module are **separate codes** (IBa_100 / IBa_50, IPK_alt / IPK_neu).

### Usage Scenarios

- `CurriculumModule` `IAD` is created once.
- When the `Handbook` *Informatik BSc 100%, WS 2027/28* adds `IAD`, the `ModuleEdition` (IAD, WS 2027/28) is found or created.
- `MA4` is taught in English from WS 2027/28: its WS 2027/28 `ModuleEdition` gets `language: en` and name "Linear Algebra I" there. The WS 2026/27 `ModuleEdition` keeps "Lineare Algebra I".

---

## Term (MaMpf, reused)

```admonish info "What it represents"
A semester, e.g., "WS 2026/27". Existing MaMpf model, no changes.
```

| Used by | Via |
|---------|-----|
| `Handbook::Handbook` | `belongs_to :term` |
| `Handbook::ModuleEdition` | `belongs_to :term` |

### Behavior Highlights

- The old system's `Start` / `Ende` dates are not needed for handbooks.
- The old system had future semesters created in advance (up to 2030). In MaMpf, the target `Term` must exist before "Prepare a term". TODO: check who can create terms in MaMpf.
- Old "copy to next Semester" is replaced by "Prepare a term" (see [Cloning](16-cloning.md)).

---

## Migration from the Old System

- `code` from Name (printed form, e.g. `MB1`); Kurz (`MB01`) only sorts. ⚑ see [To Verify](pending-thing-need-to-verify.md#3-base-data--lookups).
- `title` from the first part of Info (before the first comma), else from the newest Modul name. Empty Info (placeholders MG*, MH*, …) → empty title, flagged.
- `subject_area` from Fachgebiet; `select ...` (ITA, SCAP, SCASP, SCMa, SCS, TEST) → flagged.
- `notes` = Info as is.
- `active` = has a Modul in the newest semester with modules; flagged when Info says otherwise ("nicht mehr im MHB").
- `StudyProgram.expires_on`: `2099-01-01` → empty.
- `Term`: matched by name (`Wintersemester 2026/27`); Start / Ende dropped.

## Not Migrated

| Old | Why |
|-----|-----|
| Fachgebiet table | Enum `subject_area` on `CurriculumModule` |
| Course Cycle table | Old values: other, SS, WS, WS/SS. Not referenced by the Modul edit form (Turnus is free text there), so dropped. `cycle` on `ModuleEdition` comes from Turnus |
| Course Source table | Old values: 01 Admin, 02 Semester‑Copy, 03/04 Dozent, 05 Test. Not in the Modul edit form → the old system set it itself. Derived: Semester‑Copy = `cloned_from` set and not edited since; Admin / Dozent = who edited last (needs History); Test = not migrated |
| Fachgebiet on the per‑semester Modul | Belongs to `CurriculumModule`, not to the term |

```admonish warning "⚑ To verify: lookup values move from the UI into code"
In the old system, everyone with edit access could add or change lookup values directly in the UI (Fachgebiet, Course Cycle, Course Source tables). In the new system:

- `subject_area` is an **enum** → a new value (e.g., a 4th Fachgebiet) needs a code change and a deploy, done by a developer. Staff can no longer do it themselves in the UI.
- `cycle` is free text → nothing to maintain.
- Source is derived → nothing to maintain.

**TODO: ask the staff:**
1. Has a new Fachgebiet (or Course Cycle / Course Source value) ever been added or renamed, and how often?
2. Is it acceptable that this now goes through a developer?
```

**Suggestion:** keep the enum if the answer is "never / almost never" (3 values, tied to the faculty's structure). If values do change, use a small table editable in the UI, `handbook_subject_areas` (name DE/EN, position) instead; that costs one model, one list / edit screen and a migration of the 3 values.



---

## Database Tables

- `handbook_study_programs` - `StudyProgram`
- `handbook_curriculum_modules` - `CurriculumModule`