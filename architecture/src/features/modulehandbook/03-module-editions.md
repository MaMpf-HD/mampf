# Module Editions (Model) + Edition Copier (Service)

```admonish question "What is a 'Module Edition'?"
A module edition is the **description** of one catalog module for one term.

- **Common Examples:** "Lineare Algebra I, WS 2026/27, German, 8 ECTS", "Linear Algebra I, WS 2027/28, English, 8 ECTS"

```

## Problem Overview

- Content, language of instruction, lecturer and ECTS can change between terms, so a description must be term‑specific.
- The same edition appears in several handbooks of the same term (e.g., Bachelor 100% and Master 100%). It must be written once, not per handbook.
- Official handbooks / previewed versions content / page exporting (or sth like that) is affected by status of the ModuleEdition (#TODO: Verify this).

## Solution Architecture

- **One Module Edition per (Curriculum Module, Term)**
  * Although this is declared that a pair (Curriculum Module, Term) should point into 1 description only, regardless of study program. However I still feel the potential of different program can have different description for a pair (Curriculum Module, Term). #TODO: implement this in the way that future adjustment is possible
- Handbooks link editions through `Handbook::SectionEntry`.
- **Status** on the edition: `created` as default, and `checked`,`published`
  * Currently it seems like there is no specific lifecycle here #TODO: specify this
  * It is a suggestion from Claude that changing the content should reset the status back to "created".
- Potential `cloned_from_id` records where copied content came from (although I do not see the value of this history tracing)


## Handbook::ModuleEdition (ActiveRecord Model)

```admonish info "What it represents"
The description of one curriculum module in one term, as it appears in every handbook having that curriculum module of that term.
```

```admonish tip "Think of it as"
- **Teaching Analogy:** The page "Lineare Algebra I" in the WS 2026/27 handbook, shared by every study program that offers it that term.
```

| Name/Field | Type/Kind | Description |
|------------|-----------|-------------|
| `curriculum_module_id` | DB column | Foreign key to `Handbook::CurriculumModule` |
| `term_id` | DB column | Foreign key to MaMpf `Term` |
| `language` | DB column (Enum) | Language of instruction: `de`, `en` |
| `ects` | DB column | Credit points |
| `description` columns | DB columns (Markdown) | Content and goals |
| `status` | DB column (Enum) | `created`, `checked`, `published` |
| `cloned_from_id` | DB column | Source edition this was copied from (nullable) |
| `section_entries` | Association | Where this edition is listed |
| `handbooks` | Association | Handbooks listing it (through section_entries) |
| `display_name` | Method | Name in the edition's language |
| `check!` / `publish!` / `reopen!` | Methods | Status transitions |



### Behavior Highlights

- Unique on (`catalog_module_id`, `term_id`)
- Shared across handbooks of the same term; the edit page shows "Used in: …" so the admin sees the reach of a change.
- Cannot be destroyed while any `SectionEntry` references it.
- Status is per edition -> an edition published for Bachelor 100% is published for Master 100% too.


---

## Handbook::EditionCopier (Service Object)
```admonish info "What it represents"
Builds a new edition for a **target term** from an **source module edition**.
```

| Method | Purpose |
|--------|---------|
| `initialize(source, term:)` | Source edition and target term |
| `call` | Returns the target‑term edition: existing one if present, otherwise a new copy |

### Behavior Highlights

- Never creates a second edition for the same (module, term); returns the existing one untouched.
- Copies content fields; sets `status: :created` and `cloned_from: source`.


```admonish warning "Race condition"
Two admins cloning into the same term at once
```

## Database Tables

- `handbook_module_editions` - Per‑term module descriptions with status and lineage