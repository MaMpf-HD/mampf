# Future Extensions

Ideas that are **not** part of the first version. Each one notes why it is left out and when it would become worth building.

## Enforced review workflow

```admonish warning "May not be needed"
The first version keeps the old behavior: `created` / `checked` / `published` is a manual flag, any value can be set directly, and saving never changes it (see [Review & Publish](14-review-and-publish.md)). Build this only if several people start working on the same descriptions and someone has to approve changes before they go live.
```

**Idea:** turn the manual flag into a workflow.

- **Fixed order**: `created` → `checked` → `published`; no jump from `created` to `published`.
- **Approver**: the author marks `checked`, a second person (e.g., an `approver` role, or the admin when lecturers edit their own modules) publishes.
- **Reset on edit**: saving a printed field (`language`, `name`, `lv_number`, `ects`, text fields) of a `checked` or `published` description sets it back to `created`, so a changed text cannot go live unreviewed. Internal fields (`internal_remarks`, `responsible_user_id`) do not reset it. The save asks first and names every affected handbook.
- **Invariant**: a `checked` / `published` description always matches the content that was reviewed (`before_update :reset_status_on_content_change`).

**When it becomes useful:** together with the lecturer role below, since lecturers would edit and the admin would approve.

## Lecturer role

Lecturers edit their own descriptions (`responsible_user_id`), like the old Dozent tab. See [Roles & Permissions](00c-roles-and-permissions.md).

## Link to MaMpf `Lecture`

An optional link from a `ModuleEdition` to the `Lecture` that teaches it, e.g., to prefill lecturers or show the description on the lecture page.

## Export snapshots

Keep a copy of every official export (replaces the old Git Export), so an issued PDF can be reproduced later.
