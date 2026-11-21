# Integrity & Invariants

This chapter lists the rules that must always hold, where each is enforced, and how to check it on existing data.

## Invariants

| # | Invariant | Enforced by | Level |
|---|-----------|-------------|-------|
| I1 | At most one edition per (catalog module, term) | Unique index `handbook_module_editions(catalog_module_id, term_id)` | DB |
| I2 | At most one handbook per (study program, term) | Unique index `handbook_handbooks(study_program_id, term_id)` | DB |
| I3 | An edition appears at most once per section | Unique index `handbook_section_entries(section_id, module_edition_id)` | DB |
| I4 | An entry's edition has the handbook's term | `SectionEntry#edition_term_matches_handbook` | Model |
| I5 | Catalog module codes are unique | Unique index `handbook_catalog_modules(code)` | DB |
| I6 | Positions are contiguous per parent | `acts_as_list` (section per handbook, entry per section) | Model |
| I7 | A checked/published edition matches its reviewed content | `before_update :reset_status_on_content_change` | Model |
| I8 | Editions are never destroyed through a handbook | No `dependent` from entries to editions; `restrict_with_error` on edition → entries | Model |
| I9 | Viewers only receive published content | `HandbookAbility` + controller filter downgrade | Controller |
| I10 | Clone never overwrites an existing edition | `EditionCopier` find‑or‑create | Service |
| I11 | Clone is all‑or‑nothing | Single transaction in `CloneService#call` | Service |

```admonish note "Why I4 is not a DB constraint"
The term lives two joins away (entry → section → handbook). A check constraint cannot see it. A trigger could, but the model validation plus the fact that only `CloneService` and the entry form create entries is enough.
```

## Deletion Rules

| Object | Deleting it | Blocked when |
|--------|-------------|--------------|
| `StudyProgram` | Removes the program | Any handbook references it |
| `CurriculumModule` | Removes the module | Any edition exists |
| `ModuleEdition` | Removes the description | Any section entry references it |
| `Handbook` | Removes it, its sections and entries | Never (editions stay) |
| `Section` | Removes it and its entries | Never (editions stay) |
| `SectionEntry` | Removes the placement | Never |

## Integrity Checks

Run these before adding the unique indexes to imported data, and periodically afterwards.

```ruby
# I1: duplicate editions per (module, term)
Handbook::ModuleEdition.group(:catalog_module_id, :term_id)
                       .having("COUNT(*) > 1").count

# I4: entries whose edition term differs from the handbook term
Handbook::SectionEntry.joins(:module_edition, section: :handbook)
                      .where("handbook_module_editions.term_id <> handbook_handbooks.term_id")

# Orphans: editions in no handbook (not an error, but worth reviewing)
Handbook::ModuleEdition.where.missing(:section_entries)
```

```admonish warning "Migration hazard"
Legacy data may contain the same module with **different** text in two programs of the same term. That violates I1. Resolve each case before migrating (choose one text, or split into two catalog modules if they are genuinely different modules, e.g., different ECTS for another faculty).
```
