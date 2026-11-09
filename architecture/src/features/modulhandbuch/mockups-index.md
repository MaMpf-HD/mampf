# Mockups — Modulhandbuch

```admonish info
Purpose: index of the HTML mockups for the Modulhandbuch admin screens.
Screen decisions and flows are described in [UI Design](handbook-ui-design.md)
and [End-to-End Workflow](07-end-to-end-workflow.md).
```

```admonish tip
General mockup conventions (format, authoring checklist, change policy) are in
the main [Mockups Index](../mockups-index.md).
```

## Location

- Files: `architecture/src/mockups/modulhandbuch/`.
- All screens are admin screens. Viewer screens are not mocked yet (open
  question: are published handbooks public?).

```admonish warning "Deviation from conventions"
These mockups use hand-written CSS styled close to Bootstrap, not Bootstrap 5
itself. They will be moved to Bootstrap 5 + Bootstrap Icons together with the
planned table restyle.
```

## Index

```admonish abstract
Master data (admin)
```

- Study programs and curriculum modules (tabs, create/edit, history, delete
  rules):
  [master_data.html](../../mockups/modulhandbuch/master_data.html)

```admonish abstract
Handbooks (admin)
```

- Handbooks list (filters by program and term, pagination, new handbook,
  prepare a term):
  [module_handbooks_list.html](../../mockups/modulhandbuch/module_handbooks_list.html)
- Handbook editor (sections, add module with find-or-create, shared badges,
  description side panel, publish and export):
  [module_handbook_editing.html](../../mockups/modulhandbuch/module_handbook_editing.html)

```admonish abstract
Module descriptions (admin)
```

- Module descriptions list (filters, bulk review: mark checked, publish,
  reopen):
  [module_descriptions_list.html](../../mockups/modulhandbuch/module_descriptions_list.html)
- Module description edit (compare with previous term, step through review,
  save confirm for shared descriptions):
  [module_edition_description.html](../../mockups/modulhandbuch/module_edition_description.html)

## Change policy

- One screen per file; name it by screen and variant
  (`module_handbook_editing_empty.html`).
- When adding a mockup, link it from the relevant chapter and add it here.