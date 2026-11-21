# Module Editions (Model) + Edition Copier (Service)

````admonish question "What is a 'Module Edition'?"
A `ModuleEdition` is the **description** of one `CurriculumModule` in one `Term`.

- **Common Examples:** "MA4 Lineare Algebra I, WS 2026/27, German, 8 LP", "MA4 Linear Algebra I, WS 2027/28, English, 8 LP"
- **Old system:** Modul (StudDekanin → ModulListe / Modul Edit, Course → Course Liste, Dozent → Course-Liste)
````

## Problem Overview

- Name, content, language, lecturer and ECTS can change between terms, so a description must be term‑specific.
- The same description appears in several `Handbook`s of the same term (e.g., Informatik BSc 100% and BSc 50% both list IAD). It must be written once, not per handbook.
- Only released descriptions may appear in the official handbook; drafts must still be previewable.

## Solution Architecture

- **One `ModuleEdition` per (`CurriculumModule`, `Term`)**, regardless of study program.
  * Where programs need different texts, the old system uses **separate `CurriculumModule` codes** (IBa_100 / IBa_50, IPK_alt / IPK_neu). Keep that; no per‑program `ModuleEdition`s.
- `Handbook`s link `ModuleEdition`s through `Handbook::SectionEntry`.
- **One language per `ModuleEdition`.** Name and all text fields are written in that language and printed as is in every `Handbook`, whatever the handbook's language.
- **Printed name lives here** (`name`), not on `CurriculumModule` (see [Base Data](02-base-data.md)).
- **Status** on the `ModuleEdition`, shared by every `Handbook` that lists it.
- **`cloned_from_id`** links to the previous term's `ModuleEdition`. Needed for "Compare with previous term" (word diff while reviewing).

````admonish note "Why one language"
The old system has a DE and an EN box for every field, but in the data almost always only one is filled (e.g., IMS: EN only). One language per `ModuleEdition` matches how it is actually used.

**TODO: confirm with the staff that one language is enough.**
````

---

## Handbook::ModuleEdition (ActiveRecord Model)

````admonish info "What it represents"
The description of one `CurriculumModule` in one `Term`, as it appears in every `Handbook` of that term that lists it.
````

````admonish tip "Think of it as"
The page "IAD Algorithmen und Datenstrukturen" in the WS 2026/27 handbooks, shared by every study program that offers it that term.
````

| Name/Field | Type/Kind | Description |
|------------|-----------|-------------|
| `curriculum_module_id` | DB column | Foreign key to `Handbook::CurriculumModule` |
| `term_id` | DB column | Foreign key to MaMpf `Term` |
| `language` | DB column (Enum) | `de`, `en`; language of teaching and of the text |
| `name` | DB column | Printed name (old Modulbezeichnung) |
| `lv_number` | DB column | LV-Nr. |
| `ects` | DB column (integer) | Leistungspunkte |
| text fields | DB columns (Markdown) | See below |
| `responsible_user_id` | DB column, nullable | MaMpf `User`; for the lecturer role later |
| `internal_remarks` | DB column | Old `Dozent (intern)` + `Bemerkungen`; never exported |
| `status` | DB column (Enum) | `created`, `checked`, `published` |
| `cloned_from_id` | DB column, nullable | Previous term's `ModuleEdition` this was copied from |
| `section_entries` | Association | Where this `ModuleEdition` is listed |
| `handbooks` | Association | `Handbook`s listing it (through `section_entries`) |
| `check!` / `publish!` / `reopen!` | Methods | Status transitions |

**Text fields** (one column each, Markdown):

| Column | Old field |
|--------|-----------|
| `lecturers` | Lehrende |
| `workload` | Arbeitsaufwand |
| `duration` | Dauer |
| `cycle` | Turnus (replaces Course Cycle) |
| `format` | Lehrform / SWS |
| `learning_goals` | Lernziele |
| `topics` | Inhalt |
| `prerequisites` | Voraussetzungen |
| `usability` | Verwendbarkeit |
| `exam_scheme` | Prüfungsschema |
| `exam_modalities` | Prüfungsmodalitäten |
| `credit_award` | Vergabe der LP |
| `literature` | Literatur |

The export order and labels follow the old single‑module PDF (LV‑Nr., Name, Kürzel, LP, Dauer, Angebotsturnus, Format, Arbeitsaufwand, Verwendbarkeit, Sprache, Lehrende, Prüfungsschema, Lernziele, Lerninhalte, Teilnahmevoraussetzungen, Vergabe der LP und Modulendnote, Nützliche Literatur). Labels are printed in the `Handbook`'s language; the values in the `ModuleEdition`'s language.

### Status Lifecycle

````mermaid
stateDiagram-v2
    [*] --> created: new or copied
    created --> checked: Mark checked
    checked --> published: Publish
    checked --> created: Reopen / content saved
    published --> created: Reopen / content saved
````

- New and copied `ModuleEdition`s start as `created`.
- Saving `language`, `name`, `lv_number`, `ects` or a text field of a `checked` or `published` `ModuleEdition` resets it to `created`. The save asks first and names every affected `Handbook`.
- `internal_remarks` and `responsible_user_id` do not reset the status.
- Official export shows `published` only; draft export shows all (old: PDF vs Draft PDF, `draft=1`).

```admonish warning "⚑ Decision: keep checked?"
The old system has only released / not released. `checked` is useful if review and release are separate steps (or separate people). If one person does both, drop it: `created` → `published`.
```

### Behavior Highlights

- Unique on (`curriculum_module_id`, `term_id`), with a DB unique index.
- Term guard: only listed in `Handbook`s of the same `Term` (see [Handbooks](04-handbooks.md)).
- Shared across `Handbook`s of the same term; the edit page shows "Used in: …" so the admin sees the reach of a change.
- Cannot be destroyed while any `SectionEntry` references it. Not in any `Handbook` → shown as "Not in any handbook" in the list, deletable there.
- Status is per `ModuleEdition` → published for BSc 100% means published for BSc 50% too.

### Migration from the Old System

- Take the language whose fields are filled. If both are filled, take the one matching Lehrsprache and flag the record for manual check.
- `name` from Modulbezeichnung in the chosen language.
- `ects` from Leistungspunkte; non‑integer values (e.g., "6 or 8") are flagged for manual fix.

---

## Handbook::EditionCopier (Service Object)

```admonish info "What it represents"
Finds or builds the `ModuleEdition` for a **target term** from a **source `ModuleEdition`**.
```

| Method | Purpose |
|--------|---------|
| `initialize(source, term:)` | Source `ModuleEdition` and target `Term` |
| `call` | Returns the target‑term `ModuleEdition` (existing one if present, otherwise a new copy) and whether it was created |

### Behavior Highlights

- Never creates a second `ModuleEdition` for the same (`CurriculumModule`, `Term`); returns the existing one untouched, whatever its status.
- Copies `language`, `name`, `lv_number`, `ects`, all text fields, `responsible_user_id`; sets `status: :created` and `cloned_from: source`. Does not copy `internal_remarks`.

```admonish warning "Race condition"
Two admins cloning into the same term at once: both see "missing" and both insert. The unique index rejects the second insert; `EditionCopier` rescues `ActiveRecord::RecordNotUnique` and returns the existing `ModuleEdition` as reused.
```

---

## Not Migrated

| Old | Why |
|-----|-----|
| Fachgebiet, Kürzel / Code on Modul | Come from `CurriculumModule` |
| Second language of every field (DE/EN pairs) | One language per `ModuleEdition` |
| LV-Nr. (EN), Leistungspunkte (EN) | One value is enough |
| `prerequisites`, `sugknowledge`, `objective` (JSON) | Obsolete since WS 2015/16 |
| Course Source (Quelle) | Derived from history and `cloned_from` |
| `sws_vorlesung`, `sws_uebung`, `leistungspunkte_lsf`, `typ_veranstaltung_lsf`, `lsfsort`, LSF-Sortierung | **TODO: verify if still needed (LSF replaced by heiCO since SoSe 2024). Do not implement anything related to this.** |

---

## Database Tables

- `handbook_module_editions` - Per‑term module descriptions with status and lineage
````

**Follow-up in the Base Data file:** the ⚑ name box there still says `name_de`, `name_en` on `ModuleEdition`. It becomes:
- **B. On `ModuleEdition`** (`name`, in the `ModuleEdition`'s language, copied to the next term on clone).
- Usage scenario: "…the admin sets `language: en` and name "Linear Algebra I" on the WS 2027/28 `ModuleEdition`…"
