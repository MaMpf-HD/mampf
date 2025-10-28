# View Architecture

This chapter outlines view conventions and examples for the MÜSLI integration. It pairs with the Controller Architecture chapter and focuses on HTML ERB views, Hotwire (Turbo Frames/Streams), and ViewComponents usage.

```admonish tip "How to read this chapter"
This chapter specifies view conventions and key screens by feature area.
It complements Controllers: prefer HTML + Turbo (Frames/Streams) with
server-rendered ERB and minimal JS via Stimulus.
```

### At a glance

| Area         | Key views/components                                 | Primary callers                     |
|--------------|-------------------------------------------------------|-------------------------------------|
| Registration | Campaigns (index/show/forms), Student Registration    | Teacher/Editor UI, Student UI       |
| Roster       | Maintenance (index/show/edit/swap)                    | Teacher/Editor UI                   |
| Assessment   | Assessments (CRUD), Grading table, Participations     | Teacher/Editor UI, Tutor UI, Student|
| Exam         | Exams (CRUD), Eligibility table                       | Teacher/Editor UI                   |
| GradeScheme  | Schemes (preview/apply)                               | Teacher/Editor UI                   |
| Dashboard    | Student dashboard, Teacher/Editor dashboard           | Student UI, Teacher/Editor UI       |

The feature sections below (Registration Screens, Rosters, Assessments,
Exams & Eligibility, Grade Schemes) include two tables:
- A Screens table to summarize each screen's purpose, main UI parts,
  and interaction model at a glance. It helps designers and developers
  align on scope and Hotwire usage, and links to static mockups when
  available.
- A Controller/action mapping table to tie those screens to concrete
  Rails endpoints and roles. It clarifies routing, authorization, and
  which actions are invoked from each screen.
The following keys apply:

```admonish info "Table keys (all sections)"
Screens tables:
- View: page/screen name.
- Key elements: main UI parts.
- Hotwire: Frames/Streams used on this screen (when listed).
- Mockup: link to static HTML when available.

Mapping tables:
- View: the screen the row refers to (links to mockup if present).
- Role: actor (Teacher/Editor, Tutor, Student) when access differs.
- Controller: Rails controller handling the request.
- Actions: controller actions called from the view.
- Scope/Notes: brief intent or constraints.
```

## Conventions

- Templates: ERB (`.html.erb`).
- Components: ViewComponents in `app/frontend/_components/` or feature folders.
- Hotwire: Prefer Turbo Frames for scoped interactions; Turbo Streams for incremental/broadcast updates.
- Stimulus: Use `.controller.js` suffix; colocate with feature folder under `app/frontend/`.
- Styling: SCSS; colocate per feature when practical.

### Turbo Frames vs Turbo Streams

- Frames: Scoped navigation and partial page updates. Use for tabs, inline
	forms, pagination, filters, and detail panels so only a fragment reloads.
- Streams: Incremental updates pushed after an action or background job.
	Use for append/replace of items, progress, and results broadcast.

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

## Mockups

```admonish example "Mockups"
Preview static screens while wiring controllers and models. Mockup
links also appear in the per-feature tables below. All mockups are
styled with Bootstrap 5 (via CDN) to match the app's component library
for faster transfer from mockup to real views.

Yellow underlined rows in tables visualize an inline edit state of the
preceding white row. Mockups may show both side-by-side to illustrate
the edit UI; in the real UI, only one would be visible at a time.

```

## Registration Screens



```admonish tip "Turbo usage in Student Registration"
- Index: Frames for filters/pagination. No streams.
- Show: Frames for eligibility/details/preferences panels. Streams for
	allocation results once the job finishes.
- Preferences: Frame-wrapped form. Save returns the updated panel or
	validation errors within the frame.
 
 - Eligibility on Index: Only open campaigns surface eligibility
   badges. Closed campaigns emphasize the student's registration state
   (registered vs not registered) instead of re-stating eligibility.
```

### Campaigns (Teacher/Editor)

#### Screens

See Table keys above for column meanings.

```admonish tip "Settings live in Show"
All campaign settings are edited inline on the Show page via the
Settings tab. There is no separate Settings page.
```

```admonish note
When a campaign is completed, the Settings tab is read-only. The
"Planning-only" option is visible but disabled. In Draft/Open, the
"Planning-only" option can be toggled; enabling it hides finalization
paths in the UI (Allocation/Finalize).
```

| View   | Key elements                                          | Hotwire           | Mockup |
|--------|--------------------------------------------------------|-------------------|--------|
| Index (Lecture) | Minimal table for a single lecture; status chips       | Frames            | [Mockup](../mockups/campaigns_index.html) |
| Index (Current term, grouped) | Grouped by lecture for the teacher/editor; no search needed | Frames | [Mockup](../mockups/campaigns_index_current_term.html) |
| Show (Exam – FCFS) | Summary panel; tabs: Overview, Settings, Items, Policies, Registrations, Allocation; FCFS shows eligibility | Frames + Streams | [Mockup](../mockups/campaigns_show_exam.html) |
| Show (Tutorials – FCFS, open) | Summary panel; tabs: Overview, Settings, Items, Policies, Registrations, Allocation; FCFS shows eligibility | Frames + Streams | [Mockup](../mockups/campaigns_show_tutorial_fcfs_open.html) |
| Show (Tutorials – preference-based, open) | Summary panel; tabs: Overview, Settings, Items, Policies, Registrations, Allocation; preference-based shows preferences | Frames + Streams | [Mockup](../mockups/campaigns_show_tutorial_open.html) |
| Show (Tutorials – preference-based, completed) | Summary panel; tabs: Overview, Settings, Items, Policies, Registrations, Allocation; preference-based shows preferences | Frames + Streams | [Mockup](../mockups/campaigns_show_tutorial.html) |
| Show (Interest – draft) | Summary panel; tabs: Overview, Settings, Items, Policies, Registrations, Allocation | Frames + Streams | [Mockup](../mockups/campaigns_show_interest_draft.html) |
| Forms (Items & Policies tabs) | Inline create/edit for items and policies              | Frames            | See Show mockups (tabs) |



#### Flow

```mermaid
flowchart LR
  subgraph "Teacher/Editor"
    CIDX[Index] --> CNEW[New]
    CIDX --> CSHW[Show]
    CSHW --> OVW[Overview tab]
    CSHW --> SET[Settings tab]
    CSHW --> ITM[Items tab]
    CSHW --> POL[Policies tab]
    CSHW --> REGS[Registrations tab]
    CSHW --> ALLOCT[Allocation tab]
    CSHW --> CLOSE[Close registration]
    CLOSE --> ALLOC[Run allocation]
    ALLOC --> FIN[Finalize]
  end
```

#### Controller/action mapping (teacher/editor)
| View/Area | Controller                             | Actions                                     | Scope/Notes |
|-----------|----------------------------------------|---------------------------------------------|-------------|
| Index     | [Registration::CampaignsController](11-controllers.md#registration-controllers)      | index                                       | List campaigns for a lecture |
| Show      | [Registration::CampaignsController](11-controllers.md#registration-controllers)      | show                                        | Campaign overview with tabs |
| New/Edit (Campaign settings) | [Registration::CampaignsController](11-controllers.md#registration-controllers)      | new, create, edit, update, destroy          | Create/modify metadata and dates; destroy only if no registrations |
| Open for registration (member action) | [Registration::CampaignsController](11-controllers.md#registration-controllers)     | open                                        | Set status to open (draft → open) |
| Close/Reopen (member actions) | [Registration::CampaignsController](11-controllers.md#registration-controllers)     | close, reopen                               | Close stops intake (open → processing); reopen before finalization (processing → open) |
| Policies tab (forms) | [Registration::PoliciesController](11-controllers.md#registration-controllers)       | index, new, create, edit, update, destroy   | Manage eligibility policies within a campaign |
| Allocation tab        | [Registration::AllocationController](11-controllers.md#registration-controllers)    | show, create, retry, finalize, allocate_and_finalize | Trigger/monitor allocation; finalize moves confirmed users to rosters; hidden for planning-only |

```admonish info "Actions map — Campaigns Show"
| Control                  | Controller#action                              | Verb  | Turbo  | Preconditions                 |
|--------------------------|-------------------------------------------------|-------|--------|-------------------------------|
| Open registration        | Registration::Campaigns#open                    | POST  | Frame  | Draft only                    |
| Close registration       | Registration::Campaigns#close                   | POST  | Frame  | Open only                     |
| Reopen registration      | Registration::Campaigns#reopen                  | POST  | Frame  | Processing only               |
| Run allocation           | Registration::Allocation#create                 | POST  | Stream | Processing; not planning-only |
| Retry allocation         | Registration::Allocation#retry                  | POST  | Stream | After failure                 |
| Finalize                 | Registration::Allocation#finalize               | POST  | Stream | Allocation ready; not planning-only |
| Allocate and finalize    | Registration::Allocation#allocate_and_finalize  | POST  | Stream | Shortcut path                 |
```

### Student Registration

#### Screens

| View | Key elements | Hotwire | Mockup |
|------|---------------|---------|--------|
| Index (tabs) | Tabs: Courses & seminars, Exams; global filters with per-tab scoping; groups: Open, Closed (you registered), Closed (not registered) | Frames (filters) | [Mockup](../mockups/student_registration_index_tabs.html) |
| Show (preference-based) | Rank-first preferences (K=6, M=5), searchable catalog with pagination, add/remove/reorder ranks, save status | Frames + Streams | [Mockup](../mockups/student_registration.html) |
| Show (FCFS) | Register/Withdraw for whole course (e.g., seminar), live seat counters, async save with status | Frames | [Mockup](../mockups/student_registration_fcfs.html) |
| Show (FCFS – tutorials) | Choose a specific tutorial; per-group capacity/filled, disabled when full; async save with status | Frames | [Mockup](../mockups/student_registration_fcfs_tutorials.html) |
| Show (FCFS – exam) | Exam seat registration; date/time/location details; register/withdraw; hall capacity info; async save with status | Frames | [Mockup](../mockups/student_registration_fcfs_exam.html) |
| Show (FCFS – exam; action required: institutional email) | Registration gated by allowed email domain (policy: institutional_email); page links to Account settings to update email, then enables Register when the account email matches allowed domains | Frames | [Mockup](../mockups/student_registration_fcfs_exam_action_required_email.html) |
| Show (FCFS – exam; action required) | Same as exam, but gated by required info (ID type/number, exam rules confirmation) before Register is enabled | Frames | [Mockup](../mockups/student_registration_fcfs_exam_action_required.html) |
| Confirmation (result) | Completed registration outcome; shows assignment (e.g., Tutorial group C) and preference summary | Frames | [Mockup](../mockups/student_registration_confirmation.html) |

#### Flow

```mermaid
flowchart LR
  subgraph Student
    IDX[Index] --> SHW[Show]
    SHW --> GATE{Requirements met?}
    GATE -->|No| REQS[Fulfill requirements]
    REQS --> GATE
    GATE -->|Yes| MODE{Mode}
    MODE -->|Preference-based| PREF[Set preferences]
    PREF --> SUBMIT[Submit]
    SUBMIT --> CONF_PREF[Confirmation submitted]
    CONF_PREF -.-> ALLOC[Allocation results after close]
    MODE -->|FCFS| REG[Register or withdraw]
    REG --> CONF_FCFS[Confirmation enrolled/withdrawn]
  end

  subgraph TeacherEditor
    MGT[Manage Campaigns]
  end
```


```admonish note
Teacher/Editor “Manage Campaigns” configures mode, policies, and dates
that govern the Student flow. It does not imply a navigation path to the
Student “Show”.
```

#### Controller/action mapping (student)
| View                     | Controller                                | Actions       | Scope/Notes                           |
|--------------------------|-------------------------------------------|---------------|----------------------------------------|
| Index (tabs)             | [Registration::UserRegistrationsController](11-controllers.md#registration-controllers) | index         | Tabs: Courses & seminars, Exams; filters: Status, Registration, Semester |
| Show (preference-based)  | [Registration::UserRegistrationsController](11-controllers.md#registration-controllers) | show          | Campaign registration page (rank-first) |
| Preferences panel (Show) | [Registration::UserRegistrationsController](11-controllers.md#registration-controllers) | edit, update  | Frame; edit/update preferences         |
| Show (FCFS)              | [Registration::UserRegistrationsController](11-controllers.md#registration-controllers) | show          | FCFS enroll/withdraw                   |
| Confirmation             | [Registration::UserRegistrationsController](11-controllers.md#registration-controllers) | show          | After submit; Streams for allocation   |
| Withdraw                 | [Registration::UserRegistrationsController](11-controllers.md#registration-controllers) | destroy       | Optional, if enabled                   |

<!-- consolidated into Screens table above -->

```admonish info "Actions map — Student Registration"
| Control                              | Controller#action                               | Verb   | Turbo | Preconditions                               |
|--------------------------------------|--------------------------------------------------|--------|-------|----------------------------------------------|
| Save preferences                      | Registration::UserRegistrations#update           | PATCH  | Frame | Valid ranks only                             |
| Register (FCFS course)                | Registration::UserRegistrations#update           | PATCH  | Frame | Eligibility satisfied; seats available       |
| Choose tutorial + Register            | Registration::UserRegistrations#update           | PATCH  | Frame | FCFS tutorials; seats available              |
| Register (exam)                       | Registration::UserRegistrations#update           | PATCH  | Frame | Requirements met                             |
| Withdraw                              | Registration::UserRegistrations#destroy          | DELETE | Frame | Only when registered                         |
| Fulfill requirements (email)          | Account settings (link-out)                      | GET    | n/a   | External; updates account email              |
```

## Rosters (Teacher/Editor)

#### Flow

```mermaid
flowchart LR
  subgraph "Teacher/Editor"
    OVR[Overview] --> DET[Detail]
    DET --> EDIT[Edit and update]
    DET --> SWAP[Swap]
  end
  subgraph "Tutor"
    DETR[Detail read only]
  end
```

| View     | Key elements                                       | Hotwire | Mockup |
|----------|-----------------------------------------------------|---------|--------|
| Overview | Per-group cards; capacity meter; participant counts | Frames  | TODO   |
| Detail   | Table with add/remove/move; swap via two-selects    | Frames  | TODO   |

#### Controller/action mapping (role-specific)
| View    | Role           | Controller                    | Actions              | Scope/Notes                                  |
|---------|----------------|-------------------------------|----------------------|-----------------------------------------------|
| Overview| Teacher/Editor | [Roster::MaintenanceController](11-controllers.md#roster-controllers) | index                | Overview across rosters                       |
| Detail  | Teacher/Editor | [Roster::MaintenanceController](11-controllers.md#roster-controllers) | show, edit, update   | Single roster; inline edit frame; persist     |
| Detail  | Teacher/Editor | [Roster::MaintenanceController](11-controllers.md#roster-controllers) | swap                 | Perform swap; stream or frame update          |
| Detail  | Tutor          | [Roster::MaintenanceController](11-controllers.md#roster-controllers) | show                 | Read-only for own groups (if permitted)       |
| —       | Student        | —                             | —                    | No access to roster maintenance               |

## Assessments

#### Flow

```mermaid
flowchart LR
  subgraph "Teacher/Editor"
    SETUP[Setup] --> GR[Grading]
    GR --> PUB[Publish results]
  end
  subgraph "Tutor"
    GRT[Grading entry]
  end
  subgraph "Student"
    RES[Results]
  end
  PUB --> RES
```

| View        | Key elements                                        | Hotwire            | Mockup |
|-------------|------------------------------------------------------|--------------------|--------|
| Setup (CRUD)| Title, points/submission flags; tasks table          | Frames             | TODO   |
| Grading     | Sticky header table; per-task columns; bulk actions  | Frames + Streams   | TODO   |
| Results     | Compact totals; collapsible per-task breakdown       | Frames             | TODO   |

#### Controller/action mapping (role-specific)
| Role          | Controller                          | Actions                                           | Scope                          |
|---------------|-------------------------------------|---------------------------------------------------|---------------------------------|
| Teacher/Editor| [Assessment::AssessmentsController](11-controllers.md#assessment-controllers)   | index, new, create, show, edit, update, destroy   | Setup                          |
| Teacher/Editor| [Assessment::AssessmentsController](11-controllers.md#assessment-controllers)   | publish_results, unpublish_results                | Visibility lifecycle            |
| Teacher/Editor| [Assessment::GradingController](11-controllers.md#assessment-controllers)       | show, update, export, import                      | Grading + bulk ops             |
| Tutor         | [Assessment::GradingController](11-controllers.md#assessment-controllers)       | show, update                                      | Grading (enter/update points)  |
| Tutor         | [Assessment::GradingController](11-controllers.md#assessment-controllers)       | export, import                                    | Optional if permitted           |
| Tutor         | [Assessment::AssessmentsController](11-controllers.md#assessment-controllers)   | index, show                                       | Read-only                       |
| Student       | [Assessment::ParticipationsController](11-controllers.md#assessment-controllers)| index, show                                       | Own results (when published)    |

## Exams & Eligibility

#### Flow

```mermaid
flowchart LR
  subgraph "Teacher/Editor"
    CR[Create exam] --> REV[Review eligibility]
    REV --> OV[Optional overrides]
    OV --> EXP[Export list]
  end
  subgraph "Tutor"
    RE[Eligibility (view if permitted)]
    RED[Exam details (view if permitted)]
  end
```

| View       | Key elements                                  | Hotwire | Mockup |
|------------|-----------------------------------------------|---------|--------|
| Exams      | Date/location schedule; links to eligibility   | Frames  | TODO   |
| Eligibility| Filterable table; override modal in a frame    | Frames  | TODO   |

#### Controller/action mapping (role-specific)
| View       | Role           | Controller                        | Actions                                 | Scope/Notes                                  |
|------------|----------------|-----------------------------------|-----------------------------------------|-----------------------------------------------|
| Exams      | Teacher/Editor | [ExamsController](11-controllers.md#exam-controllers)                    | index, new, create, show, edit, update, destroy | Manage exams                            |
| Eligibility| Teacher/Editor | [ExamEligibility::RecordsController](11-controllers.md#exam-controllers) | index, show, update, export             | Eligibility management (override/export)      |
| Eligibility| Tutor          | [ExamEligibility::RecordsController](11-controllers.md#exam-controllers) | index, show                             | View if permitted; no overrides                |
| Exams      | Tutor          | [ExamsController](11-controllers.md#exam-controllers)                    | index, show                             | Read-only (if permitted by abilities)         |
| —          | Student        | —                                   | —                                       | No access here (registration handled elsewhere)|

## Grade Schemes

#### Flow

```mermaid
flowchart LR
  subgraph "Teacher/Editor"
    PRV[Preview] --> APP[Apply]
    APP --> STR[Stream updates]
  end
  subgraph "Tutor"
    PRVT[Preview read only]
  end
```

| View    | Key elements                                              | Hotwire            | Mockup |
|---------|-----------------------------------------------------------|--------------------|--------|
| Preview | Histogram; draggable boundaries; distribution table       | Frames             | TODO   |
| Apply   | Apply scheme and update results                           | Streams (+ Frames) | TODO   |

#### Controller/action mapping (role-specific)
| View    | Role           | Controller                      | Actions                               | Scope/Notes                                 |
|---------|----------------|---------------------------------|---------------------------------------|----------------------------------------------|
| Setup   | Teacher/Editor | [GradeScheme::SchemesController](11-controllers.md#grade-scheme-controllers)  | index, new, create, edit, update      | Manage schemes                               |
| Preview | Teacher/Editor | [GradeScheme::SchemesController](11-controllers.md#grade-scheme-controllers)  | preview                               | Preview distribution                         |
| Apply   | Teacher/Editor | [GradeScheme::SchemesController](11-controllers.md#grade-scheme-controllers)  | apply                                 | Apply to results; stream updates             |
| Preview | Tutor          | [GradeScheme::SchemesController](11-controllers.md#grade-scheme-controllers)  | preview                               | Read-only (if permitted by abilities)        |
| —       | Student        | —                               | —                                     | No access to grading schemes                 |

## Notes

```admonish note "Guidance"
- Keep server responses small within frames.
- Use Streams for background job progress (allocation/grades publish).
- Avoid comments/docstrings in code per repository standards. Add
	top-level docstrings when needed in actual source files.
```
