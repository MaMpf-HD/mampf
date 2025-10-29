# Mockups — index and conventions

```admonish info
Purpose: central place for mockup conventions and a curated index of the
key HTML mockups used across Registration and Campaigns flows.
```

## Conventions

- Format: plain HTML with Bootstrap 5 and Bootstrap Icons.
- JS: minimal inline JS is allowed; use localStorage to simulate state.
- Styling: prefer Bootstrap utilities; avoid custom CSS unless needed.
- Scope: illustrate UI/UX and states; not production templates.
- Accessibility: semantic tags where reasonable; label interactive
  elements.

```admonish tip
See also: View architecture → Mockups section for legend and notes:
[12-views.md](12-views.md)
```

## Authoring checklist

- File location: `architecture/src/mockups/`.
- Naming: describe screen + variant, e.g. `student_registration_fcfs.html`.
- Include: viewport meta, Bootstrap CSS/JS, Bootstrap Icons.
- Use: consistent headings, button labels, and table markup.
- Simulate: disabled/enabled states; empty/error states as needed.

## Index — Registration and Campaigns

```admonish abstract
Campaigns (admin)
```

- Campaigns index (lecture):
  [campaigns_index.html](../mockups/campaigns_index.html)
- Campaigns index (current term):
  [campaigns_index_current_term.html](../mockups/campaigns_index_current_term.html)
- Show — exam (FCFS):
  [campaigns_show_exam.html](../mockups/campaigns_show_exam.html)
- Show — tutorials (FCFS, open):
  [campaigns_show_tutorial_fcfs_open.html](../mockups/campaigns_show_tutorial_fcfs_open.html)
- Show — tutorials (preference-based, open):
  [campaigns_show_tutorial_open.html](../mockups/campaigns_show_tutorial_open.html)
- Show — tutorials (preference-based, completed):
  [campaigns_show_tutorial.html](../mockups/campaigns_show_tutorial.html)
- Show — interest (planning-only, draft):
  [campaigns_show_interest_draft.html](../mockups/campaigns_show_interest_draft.html)

```admonish abstract
Student Registration (student)
```

- Index — tabs:
  [student_registration_index_tabs.html](../mockups/student_registration_index_tabs.html)
- Show — FCFS (single-item):
  [student_registration_fcfs.html](../mockups/student_registration_fcfs.html)
- Show — FCFS (multi-item picker):
  [student_registration_fcfs_tutorials.html](../mockups/student_registration_fcfs_tutorials.html)
- Show — FCFS (exam) and policy gate:
  [student_registration_fcfs_exam.html](../mockups/student_registration_fcfs_exam.html),
  [action required: email](../mockups/student_registration_fcfs_exam_action_required_email.html)
- Show — preference-based:
  [student_registration.html](../mockups/student_registration.html)
- Confirmation screens:
  [tutorial](../mockups/student_registration_confirmation.html),
  [seminar](../mockups/student_registration_confirmation_seminar.html)

```admonish abstract
Roster maintenance (teacher/editor)
```

- Overview:
  [roster_overview.html](../mockups/roster_overview.html)
- Detail:
  [roster_detail.html](../mockups/roster_detail.html)

## Change policy

- Keep mockups small and focused on one screen/variant.
- When adding mockups, link them from the relevant feature docs and add
  them here.
