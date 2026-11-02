# Study Programs and Curriculum Modules

```admonish question "What is the 'Catalog'?"
Both Study Programs and Curriculum Modules are the admin‑verified, term‑independent master data of the handbook.

- **Common Examples:** 
  * "Mathematik, Bachelor 100%"
  * "MA101 Lineare Algebra I / Linear Algebra I"

- Records that **are the same in every term**. Everything that can differ per term lives on [Module Editions](03-module-editions.md).
```

## Problem Overview

- MaMpf `Course`/`Lecture` records are created by teachers and are not verified, so they cannot be the source of an official document.
- The same real lecture can be taught in German one term and in English the next. Its name in the handbook follows the language of instruction ("Lineare Algebra" vs. "Linear Algebra").
- Study programs come in variants (Bachelor/Master, 100%/50%) that need separate handbooks.

## Solution Architecture

- **One catalog module per real lecture**, carrying both names. The language is **not** part of the catalog; it is chosen per term on the edition, and the displayed name follows it.
- **Study programs as plain records** with degree and share as enums. A separate lookup table is only needed if the admin must manage the list of degrees.
- **Term reused from MaMpf**, no new table.


---

## Handbook::StudyProgram (ActiveRecord Model)

```admonish info "What it represents"
A degree program variant for which handbooks are written.
```

```admonish tip "Think of it as"
The cover page of a handbook: "Modulhandbuch Mathematik, Bachelor 100%".
```

| Name/Field | Type/Kind | Description |
|------------|-----------|-------------|
| `name` | DB column | Program name (e.g., "Mathematik") |
| `degree` | DB column (Enum) | `bachelor`, `master` |
| `share` | DB column (Enum) | `full` (100%), `half` (50%) |
| `handbooks` | Association | All handbooks of this program, one per term |

### Behavior Highlights

- Unique on (`name_de`, `degree`, `share`).
- Cannot be destroyed while a handbook references it (`dependent: :restrict_with_error`).

### Concern: #TODO
* do we need  `de` and `en` for `name`?
* In case we have both, how to decide which language to display? 
---

## Handbook::CurriculumModule (ActiveRecord Model)

```admonish info "What it represents"
A real‑world module, verified by the admin, independent of any term.
```

```admonish tip "Think of it as"
- "Lineare Algebra I" as an entry in the examination regulations, not the lecture that Prof. X gives in WS 2026/27.
- A verified version of `Lecture` in MaMpf
```

| Name/Field | Type/Kind | Description |
|------------|-----------|-------------|
| `code` | DB column, nullable | Unique module code (e.g., "MA101") |
| `name_de` | DB column, nullable | German name |
| `name_en` | DB column, nullable | English name |
| `module_editions` | Association | All per‑term editions of this module |
| `edition_for(term)` | Method | The edition in a given term, or `nil` |
| `name_for(language)` | Method | Name matching a language of instruction |

### Behavior Highlights

- `code` is unique, nullable
- Renaming a Curriculum module: #TODO: 
  * will renames it in **every** term, including old handbooks ...
  * however this behaviour is quite dangerous, should go with warning
- Cannot be destroyed while editions exist.
- Cloning should not be affected by language choice.
- Creation of CurriculumModule does **not lead to the eager creation** of ModuleEdition.


### Usage Scenarios

- The admin creates Curriculum module `Linear Algebra I` once. 
- When initializing Modulehandbook for specific term `WS 2027/28`, it is possible to create a `ModuleEdition` for the combination of `Linear Algebra I` and `WS 2027/28`.
- A module `Linear Algebra I / Lineare Algebra I`:
  * It is taught in English from WS 2027/28. This record in Modulehandbook of program X (WS 2027/28) is with English title "Linear Algebra I". 
  * In SS 2028, it is taught in German. Admin clones the Modulehandbook of program X (WS 2027/28) as new Modulehandbook of program X (SS 2028) and set `language: :de` for new ModuleEdition, and the new handbook shows "Lineare Algebra I". The title in WS 2027/28 version remains unchanged

---

## Database Tables

- `handbook_study_programs` - Study program variants
- `handbook_catalog_modules` - Term‑independent module identities

