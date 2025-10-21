# View Architecture

This chapter outlines view conventions and examples for the MÜSLI integration. It pairs with the Controller Architecture chapter and focuses on HTML ERB views, Hotwire (Turbo Frames/Streams), and ViewComponents usage.

```admonish tip "How to read this chapter"
This chapter specifies view conventions and key screens by feature area.
It complements Controllers: prefer HTML + Turbo (Frames/Streams) with
server-rendered ERB and minimal JS via Stimulus.
```

### At a glance

| Area         | Key views/components                                 | Hotwire                 | Primary callers             |
|--------------|-------------------------------------------------------|-------------------------|-----------------------------|
| Registration | Campaigns (index/show/forms), Student Registration    | Frames + Streams        | Admin UI, Student UI        |
| Roster       | Maintenance (index/show/edit/swap)                    | Frames                  | Admin UI                    |
| Assessment   | Assessments (CRUD), Grading table, Participations     | Frames (+ Streams)      | Admin UI, Tutor UI, Student |
| Exam         | Exams (CRUD), Eligibility table                       | Frames                  | Admin UI                    |
| GradeScheme  | Schemes (preview/apply)                               | Streams (+ Frames)      | Admin UI                    |
| Dashboard    | Student dashboard, Admin dashboard                    | Frames                  | Student UI, Teacher/Editor  |

## Conventions

- Templates: ERB (`.html.erb`).
- Components: ViewComponents in `app/frontend/_components/` or feature folders.
- Hotwire: Prefer Turbo Frames for scoped interactions; Turbo Streams for incremental/broadcast updates.
- Stimulus: Use `.controller.js` suffix; colocate with feature folder under `app/frontend/`.
- Styling: SCSS; colocate per feature when practical.

## Partials vs ViewComponents

```admonish tip "Decision guide"
Start simple. Use a partial first. Promote to a ViewComponent when the
fragment becomes reusable, complex, or needs its own tests/JS/styles.
```

| Use a partial when...                               | Use a ViewComponent when...                             |
|-----------------------------------------------------|---------------------------------------------------------|
| It is local to a single page/feature                | It is reused across pages/features                      |
| Presentation-only, minimal branching                | Encapsulates logic/variants/states                      |
| Small fragment (row, cell, inline form field)       | Owns JS/CSS (Stimulus) or wraps a reusable Frame        |
| Minimal/no Stimulus behavior                        | Needs a stable API (kwargs/slots)                       |
| No dedicated unit tests needed                      | Deserves unit tests and composition via slots           |
| No caching/memoization required                     | Will benefit from caching/memoization                   |

```admonish tip "Turbo in views"
Both partials and components can live inside Turbo Frames. If background
jobs will stream updates to the same fragment in several contexts, prefer
a component and render it from stream templates. For one-off stream
responses, a partial is fine.
```

```admonish example "Placement & API"
Partials: colocate near the parent view (e.g.,
`app/frontend/registration/.../_row.html.erb`) and pass explicit locals.

ViewComponents: place in `app/frontend/_components/` or feature-specific
folders. Prefer keyword args and slots for a clear contract.
```

```admonish info "Migration path"
Extract a growing partial into a ViewComponent without changing callers.
Keep the component API narrow and clear via initializer and slots.
```

## Layout & Partials

- Use partials for reusable fragments (tables, forms, flash bars).
- Extract repeated frame shells (table headers, pagination) into partials.
- Keep forms server-rendered; augment with Stimulus when needed.

## Registration Screens

```admonish example "Mockups"
Preview static screens while wiring controllers and models. Mockup links
also appear in the tables below.

- Student Registration: [Mockup](../mockups/student_registration.html)
```

### Campaigns (Admin)

| View   | Key elements                                          | Hotwire           | Mockup |
|--------|--------------------------------------------------------|-------------------|--------|
| Index  | Paginated table; status chips (draft/open/processing/completed) | Frames            | TODO   |
| Show   | Summary panel; tabs: Items, Policies, Registrations, Allocation | Frames + Streams  | TODO   |
| Forms  | Inline create/edit for items and policies              | Frames            | TODO   |

### Student Registration

| View         | Key elements                                    | Hotwire           | Mockup |
|--------------|--------------------------------------------------|-------------------|--------|
| Index/Show   | Available campaigns; eligibility badges          | Frames            | [Mockup](../mockups/student_registration.html) |
| Preferences  | Drag & drop or rank inputs within a frame        | Frames            | [Mockup](../mockups/student_registration.html) |
| Confirmation | Post-submit confirmation; allocation result area | Streams (results) | [Mockup](../mockups/student_registration.html) |

## Rosters (Admin)

| View     | Key elements                                       | Hotwire | Mockup |
|----------|-----------------------------------------------------|---------|--------|
| Overview | Per-group cards; capacity meter; participant counts | Frames  | TODO   |
| Detail   | Table with add/remove/move; swap via two-selects    | Frames  | TODO   |

## Assessments

| View        | Key elements                                        | Hotwire            | Mockup |
|-------------|------------------------------------------------------|--------------------|--------|
| Setup (CRUD)| Title, points/submission flags; tasks table          | Frames             | TODO   |
| Grading     | Sticky header table; per-task columns; bulk actions  | Frames + Streams   | TODO   |
| Results     | Compact totals; collapsible per-task breakdown       | Frames             | TODO   |

## Exams & Eligibility

| View       | Key elements                                  | Hotwire | Mockup |
|------------|-----------------------------------------------|---------|--------|
| Exams      | Date/location schedule; links to eligibility   | Frames  | TODO   |
| Eligibility| Filterable table; override modal in a frame    | Frames  | TODO   |

## Grade Schemes

| View    | Key elements                                              | Hotwire            | Mockup |
|---------|-----------------------------------------------------------|--------------------|--------|
| Preview | Histogram; draggable boundaries; distribution table       | Frames             | TODO   |
| Apply   | Apply scheme and update results                           | Streams (+ Frames) | TODO   |

## Notes

```admonish note "Guidance"
- Keep server responses small within frames.
- Use Streams for background job progress (allocation/grades publish).
- Avoid comments/docstrings in code per repository standards. Add
	top-level docstrings when needed in actual source files.
```
