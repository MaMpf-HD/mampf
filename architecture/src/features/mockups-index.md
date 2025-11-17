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
- Show — generic:
  [campaigns_show.html](../mockups/campaigns_show.html)
- Show — exam (FCFS):
  [campaigns_show_exam.html](../mockups/campaigns_show_exam.html)
- Show — exam (draft, incomplete certs):
  [campaigns_show_exam_draft_incomplete_certs.html](../mockups/campaigns_show_exam_draft_incomplete_certs.html)
- Show — tutorials (FCFS, open):
  [campaigns_show_tutorial_fcfs_open.html](../mockups/campaigns_show_tutorial_fcfs_open.html)
- Show — tutorials (preference-based, open):
  [campaigns_show_tutorial_open.html](../mockups/campaigns_show_tutorial_open.html)
- Show — tutorials (preference-based, completed):
  [campaigns_show_tutorial.html](../mockups/campaigns_show_tutorial.html)
- Show — interest (planning-only, draft):
  [campaigns_show_interest_draft.html](../mockups/campaigns_show_interest_draft.html)
- Preflight error modal:
  [campaigns_preflight_error_modal.html](../mockups/campaigns_preflight_error_modal.html)

```admonish abstract
Student Registration (student)
```

- Index:
  [student_registration_index.html](../mockups/student_registration_index.html)
- Index — tabs:
  [student_registration_index_tabs.html](../mockups/student_registration_index_tabs.html)
- Show — FCFS (single-item):
  [student_registration_fcfs.html](../mockups/student_registration_fcfs.html)
- Show — FCFS (multi-item picker):
  [student_registration_fcfs_tutorials.html](../mockups/student_registration_fcfs_tutorials.html)
- Show — FCFS (exam):
  [student_registration_fcfs_exam.html](../mockups/student_registration_fcfs_exam.html)
- Show — FCFS (exam, action required email):
  [student_registration_fcfs_exam_action_required_email.html](../mockups/student_registration_fcfs_exam_action_required_email.html)
- Show — FCFS (exam, failed certification):
  [student_registration_fcfs_exam_failed_certification.html](../mockups/student_registration_fcfs_exam_failed_certification.html)
- Show — FCFS (exam, pending certification):
  [student_registration_fcfs_exam_pending_certification.html](../mockups/student_registration_fcfs_exam_pending_certification.html)
- Show — preference-based:
  [student_registration.html](../mockups/student_registration.html)
- Confirmation:
  [student_registration_confirmation.html](../mockups/student_registration_confirmation.html)
- Confirmation (seminar):
  [student_registration_confirmation_seminar.html](../mockups/student_registration_confirmation_seminar.html)

```admonish abstract
Roster maintenance (teacher/editor)
```

- Overview:
  [roster_overview.html](../mockups/roster_overview.html)
- Overview (exam):
  [roster_overview_exam.html](../mockups/roster_overview_exam.html)
- Overview (seminar):
  [roster_overview_seminar.html](../mockups/roster_overview_seminar.html)
- Detail:
  [roster_detail.html](../mockups/roster_detail.html)
- Detail (exam):
  [roster_detail_exam.html](../mockups/roster_detail_exam.html)
- Detail (seminar):
  [roster_detail_seminar.html](../mockups/roster_detail_seminar.html)
- Detail (tutor):
  [roster_detail_tutor.html](../mockups/roster_detail_tutor.html)

```admonish abstract
Exams & Eligibility (teacher/editor)
```

- Exams index:
  [exams_index.html](../mockups/exams_index.html)
- Eligibility overview:
  [exams_eligibility.html](../mockups/exams_eligibility.html)
- Exam roster:
  [exam_roster.html](../mockups/exam_roster.html)
- Exams roster:
  [exams_roster.html](../mockups/exams_roster.html)
- Exams roster (tutor):
  [exams_roster_tutor.html](../mockups/exams_roster_tutor.html)
- Exams student results detail:
  [exams_student_results_detail.html](../mockups/exams_student_results_detail.html)

```admonish abstract
Assessments (teacher/editor/tutor/student)
```

- Index:
  [assessments_index.html](../mockups/assessments_index.html)
- Index (end of semester):
  [assessments_index_end_of_semester.html](../mockups/assessments_index_end_of_semester.html)
- Index (seminar):
  [assessments_index_seminar.html](../mockups/assessments_index_seminar.html)
- New:
  [assessments_new.html](../mockups/assessments_new.html)
- Show — assignment (open):
  [assessments_show_assignment_open.html](../mockups/assessments_show_assignment_open.html)
- Show — assignment (closed):
  [assessments_show_assignment_closed.html](../mockups/assessments_show_assignment_closed.html)
- Show — exam (draft):
  [assessments_show_exam_draft.html](../mockups/assessments_show_exam_draft.html)
- Show — exam (closed):
  [assessments_show_exam_closed.html](../mockups/assessments_show_exam_closed.html)
- Show — exam (graded):
  [assessments_show_exam_graded.html](../mockups/assessments_show_exam_graded.html)
- Show — exam (grading phase 1):
  [assessments_show_exam_grading_phase1.html](../mockups/assessments_show_exam_grading_phase1.html)
- Show — exam (grading phase 2):
  [assessments_show_exam_grading_phase2.html](../mockups/assessments_show_exam_grading_phase2.html)
- Show — exam (grading phase 3):
  [assessments_show_exam_grading_phase3.html](../mockups/assessments_show_exam_grading_phase3.html)
- Show — exam (grading phase 4):
  [assessments_show_exam_grading_phase4.html](../mockups/assessments_show_exam_grading_phase4.html)
- Show — talk:
  [assessments_show_talk.html](../mockups/assessments_show_talk.html)
- Grading (tutor):
  [assessments_grading_tutor.html](../mockups/assessments_grading_tutor.html)
- Student results overview:
  [assessments_student_results_overview.html](../mockups/assessments_student_results_overview.html)
- Student results detail:
  [assessments_student_results_detail.html](../mockups/assessments_student_results_detail.html)

```admonish abstract
Lecture Performance (teacher/editor/student)
```

- Certifications index:
  [lecture_performance_certifications_index.html](../mockups/lecture_performance_certifications_index.html)
- Certification remediation:
  [lecture_performance_certification_remediation.html](../mockups/lecture_performance_certification_remediation.html)
- Records index:
  [lecture_performance_records_index.html](../mockups/lecture_performance_records_index.html)
- Rule configuration:
  [lecture_performance_rule_configuration.html](../mockups/lecture_performance_rule_configuration.html)
- Rule change preview:
  [lecture_performance_rule_change_preview.html](../mockups/lecture_performance_rule_change_preview.html)
- Student overview:
  [lecture_performance_student_overview.html](../mockups/lecture_performance_student_overview.html)

```admonish abstract
Dashboards
```

- Student dashboard:
  [student_dashboard.html](../mockups/student_dashboard.html)
- Teacher/Editor dashboard:
  [teacher_editor_dashboard.html](../mockups/teacher_editor_dashboard.html)
- Teacher/Editor dashboard (start of semester):
  [teacher_editor_dashboard_start_of_semester.html](../mockups/teacher_editor_dashboard_start_of_semester.html)

```admonish abstract
Student Account
```

- Account data:
  [student_account_data.html](../mockups/student_account_data.html)

## Change policy

- Keep mockups small and focused on one screen/variant.
- When adding mockups, link them from the relevant feature docs and add
  them here.
