# Controller Architecture

This chapter outlines the controllers needed to implement the MÜSLI integration into MaMpf. Controllers are organized by functional area and follow Rails conventions with namespacing.

## Overview

```admonish tip "How to read this chapter"
We do not expose a public API. "Primary caller" refers to who invokes
the controller actions inside MaMpf: HTML forms (Turbo), background
jobs, or teacher/editor UIs. Use these sections to wire views, jobs, and
service objects to the right endpoints.
```

### At a glance

| Namespace   | Key controllers                                   | Primary caller            |
|-------------|----------------------------------------------------|---------------------------|
| Registration| Campaigns, UserRegistrations, Policies, Allocation | Teacher/Editor UI, Student UI, Job |
| Roster      | Maintenance                                        | Teacher/Editor UI         |
| Assessment  | Assessments, Grading, Participations               | Teacher/Editor UI, Tutor UI |
| StudentPerformance | Records, Certifications, Evaluator           | Teacher/Editor UI         |
| Exam        | Exams                                              | Teacher/Editor UI         |
| GradeScheme | Schemes                                            | Teacher/Editor UI         |
| Dashboard   | Dashboard, Admin::Dashboard                        | Student UI, Teacher/Editor UI |

Controllers are grouped into the following namespaces:
- Registration: Campaign setup, student registration, allocation
- Roster: Post-allocation roster maintenance
- Assessment: Assessment setup, grading, result viewing
- StudentPerformance: Performance records, teacher certification, evaluator proposals
- Exam: Exam management
- GradeScheme: Grading scheme configuration
- Dashboard: Student and teacher/editor views

```admonish tip "Turbo responses"
Controllers render HTML plus Hotwire responses:
- Turbo Frames for partial page replacement within a frame.
- Turbo Streams for broadcasting or incremental updates.
Prefer frames for scoped, request/response UI flows; prefer streams for
updates triggered by background jobs or actions affecting multiple parts
of the page.
```

## Registration Controllers

### `Registration::CampaignsController`

```admonish info "Purpose"
Manage registration campaigns for lectures.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Registration::CampaignsController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action  | Purpose |
|---------|---------|
| index   | List all campaigns for a lecture |
| new     | Form to create a new campaign |
| create  | Create campaign with divisions and policies |
| show    | View campaign details and status |
| edit    | Edit campaign settings (before allocation) |
| update  | Update campaign |
| destroy | Delete campaign (if no registrations exist) |

```admonish example "Responsibilities"
- CRUD operations for campaigns
- Validate date ranges and capacity constraints
- Display campaign status (draft, open, closed, processing, completed)
- **Pre-flight checks:** Before opening campaigns with `student_performance` policies:
  - Verify all lecture students have `StudentPerformance::Certification` records
  - Ensure all certifications have `status: :passed` or `:failed` (no `pending`)
  - Block campaign opening with clear error message if checks fail
- **Pre-finalization checks:** Before finalizing campaigns:
  - Re-validate certification completeness
  - Check for stale certifications (due to rule changes or record updates)
  - Prompt remediation workflow if issues exist
```

### `Registration::UserRegistrationsController`

```admonish info "Purpose"
Handle the student registration flow.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Registration::UserRegistrationsController | Student UI | HTML, Turbo Frames/Streams |

**Actions**

| Action  | Purpose |
|---------|---------|
| index   | Show available campaigns for current user |
| new     | Pre-flight eligibility check; show registration form if eligible, error message if not |
| create  | Submit registration with ranked preferences (preference-based) or direct registration (FCFS) |
| show    | View registration status and assigned roster |
| edit    | Modify preferences (before allocation deadline) |
| update  | Update preferences |
| destroy | Withdraw from campaign |

```admonish example "Responsibilities"
- Pre-flight eligibility check on page load via `campaign.evaluate_policies_for(user, phase: :registration)`
- Conditionally render registration interface based on eligibility result
- Display clear rejection reasons when policies fail (before user invests effort)
- Display eligibility status based on `StudentPerformance::Certification`
- Show certification status (passed/failed) for exam campaigns
- Handle preference ranking (drag-and-drop or priority input)
- Show allocation results after campaign completes
- Validate registration constraints
```

### `Registration::PoliciesController`

```admonish info "Purpose"
Admin interface for managing registration policies.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Registration::PoliciesController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action  | Purpose |
|---------|---------|
| index   | List all policies for a campaign |
| new     | Create policy form |
| create  | Create eligibility or allocation policy |
| edit    | Modify policy |
| update  | Update policy |
| destroy | Remove policy |

```admonish example "Responsibilities"
- Select policy type (eligibility vs allocation scoring)
- Configure policies (score thresholds, enrollment requirements, etc.)
- Policy preview/testing interface
```

### `Registration::AllocationController`

```admonish info "Purpose"
Trigger and monitor the allocation algorithm.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Registration::AllocationController | Teacher/Editor UI, Job | HTML, Turbo Frames/Streams |

**Actions**

| Action   | Purpose |
|----------|---------|
| show     | View allocation status and preview |
| create   | Trigger allocation algorithm |
| retry    | Re-run allocation with adjusted parameters |
| finalize | Commit allocation results to rosters |
| allocate_and_finalize | Compute allocation and immediately finalize |

```admonish example "Responsibilities"
- Run allocation algorithm as background job
- Display allocation statistics (satisfaction rate, unassigned students)
- Allow parameter adjustments before finalization
- Create rosters from allocation results
- Support single-step allocate_and_finalize flow when desired
- Delegate to Campaign API: `allocate!`, `finalize!`, `allocate_and_finalize!`
- Validate certification completeness before finalization
```

## Roster Controllers

### `Roster::MaintenanceController`

```admonish info "Purpose"
Handle post-allocation roster changes.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Roster::MaintenanceController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action | Purpose |
|--------|---------|
| index  | Overview of all rosters for a lecture |
| show   | View specific roster with participants |
| edit   | Modify roster metadata (e.g., tutor/time/place) |
| update | Save roster metadata changes; perform move/add/remove |
| move   | Move students between rosters |

```admonish example "Responsibilities"
- Manual roster adjustments
- Move participants between groups
- Tutor reassignment
- Capacity override
- Does not re-run the automated solver or reopen the campaign
```

## Assessment Controllers

### `Assessment::AssessmentsController`

```admonish info "Purpose"
Configure assessments for lectures.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Assessment::AssessmentsController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action  | Purpose |
|---------|---------|
| index   | List all assessments for a lecture |
| new     | Create assessment form |
| create  | Create assessment with parameters |
| show    | View assessment details |
| edit    | Modify assessment settings |
| update  | Update assessment |
| destroy | Delete assessment (if no grades exist) |
| publish_results | Publish results to students |

```admonish example "Responsibilities"
- Create and configure assessments
- Set max points, weight, thresholds
- Configure eligibility contribution
- Link to specific divisions or entire lecture
- Control visibility lifecycle (publish/unpublish results)
```

### `Assessment::GradingController`

```admonish info "Purpose"
Enter and manage grades.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Assessment::GradingController | Tutor UI, Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action | Purpose |
|--------|---------|
| show   | Grading interface for an assessment |
| update | Bulk update grades for multiple students |
| export | Export grades as CSV |
| import | Import grades from CSV |

```admonish example "Responsibilities"
- Display grading table (filterable by roster/division)
- Bulk grade entry
- Validate grade values (0 to max_points)
- Calculate derived metrics (percentages, pass/fail)
```

### `Assessment::ParticipationsController`

```admonish info "Purpose"
Student view of assessment results.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Assessment::ParticipationsController | Student UI | HTML, Turbo Frames/Streams |

**Actions**

| Action | Purpose |
|--------|---------|
| index  | List all assessments student can view |
| show   | View grades and feedback for specific assessment |

```admonish example "Responsibilities"
- Display personal grades
- Show aggregate statistics (if configured)
- Feedback and comments from graders
```

## Exam Controllers

### `ExamsController`

```admonish info "Purpose"
Manage exam instances for lectures.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| ExamsController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action  | Purpose |
|---------|---------|
| index   | List all exams for a lecture |
| new     | Create exam form |
| create  | Create exam |
| show    | View exam details and certification summary |
| edit    | Modify exam settings |
| update  | Update exam |
| destroy | Delete exam |

```admonish example "Responsibilities"
- Exam scheduling (date, location)
- Registration deadline management
- Display certification summary (number of students passed/failed)
- Link to certification dashboard for detailed review
- Export eligible student list (students with `status: :passed`)
```

## Student Performance Controllers

### `StudentPerformance::RecordsController`

```admonish info "Purpose"
View and manage performance records (factual data only).
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| StudentPerformance::RecordsController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action | Purpose |
|--------|---------|
| index  | List performance records for all students |
| show   | Detailed performance breakdown for one student |
| recompute | Trigger recomputation for specific student(s) |
| export | Export performance data |

```admonish example "Responsibilities"
- Display factual performance data (points, achievements)
- Show computation timestamp and rule version
- Trigger manual recomputation when needed
- Export performance data for analysis
- **No eligibility interpretation** - pure factual data display
```

### `StudentPerformance::CertificationsController`

```admonish info "Purpose"
Teacher certification workflow for eligibility decisions.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| StudentPerformance::CertificationsController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action  | Purpose |
|---------|---------|
| index   | Certification dashboard showing all students |
| create  | Bulk create certifications from proposals |
| update  | Manual override of individual certification |
| bulk_accept | Accept all proposals in one action |
| remediate | Handle stale/pending certifications before campaign operations |
| export  | Export certification list |

```admonish example "Responsibilities"
- Display certification dashboard with proposals
- Show proposed status (passed/failed) for each student
- Bulk accept proposals (common case)
- Manual override with required note field
- Handle rule change diff: "12 students would change: failed → passed"
- Remediation workflow for pending/stale certifications
- Verify completeness before allowing campaign operations
- Track certification history (certified_at, certified_by)
```

### `StudentPerformance::EvaluatorController`

```admonish info "Purpose"
Generate eligibility proposals using the Evaluator service.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| StudentPerformance::EvaluatorController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action | Purpose |
|--------|---------|
| bulk_proposals | Generate proposals for all lecture students |
| preview_rule_change | Show impact of rule modifications before saving |
| single_proposal | Generate proposal for specific student (review case) |

```admonish example "Responsibilities"
- Call `StudentPerformance::Evaluator.bulk_proposals(lecture)`
- Display proposals in reviewable format
- Show rule change preview: affected students and status changes
- Generate single proposal for manual review cases
- **Does not create Certifications** - only generates proposals for teacher review
```

## Grade Scheme Controllers

### `GradeScheme::SchemesController`

```admonish info "Purpose"
Configure grading schemes for courses.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| GradeScheme::SchemesController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action  | Purpose |
|---------|---------|
| index   | List all schemes for a course |
| new     | Create grading scheme |
| create  | Save scheme with thresholds |
| edit    | Modify scheme |
| update  | Update scheme |
| apply   | Apply scheme to assessment results |
| preview | Preview grade distribution |

- Define grade thresholds (1.0, 1.3, 1.7, ..., 5.0)
- Configure bonus points and rounding policies
- Preview grade distribution before finalizing
- Apply scheme to generate final grades


## Dashboard Controllers

### `DashboardController`

```admonish info "Purpose"
Student-facing dashboard.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| DashboardController | Student UI | HTML, Turbo Frames/Streams |

**Actions**

| Action | Purpose |
|--------|---------|
| show   | Overview of all enrollments, registrations, grades |

```admonish example "Responsibilities"
- Display active campaigns requiring action
- Show roster assignments
- List assessment results
- Display exam eligibility status
```

### `Admin::DashboardController`

```admonish info "Purpose"
Teacher and editor dashboard.
```

| Controller | Primary callers | Responses |
|------------|------------------|-----------|
| Admin::DashboardController | Teacher/Editor UI | HTML, Turbo Frames/Streams |

**Actions**

| Action | Purpose |
|--------|---------|
| show   | Overview of all campaigns, rosters, assessments for managed lectures |

```admonish example "Responsibilities"
- Quick access to campaign management
- Roster statistics and allocation quality metrics
- Grading progress tracking
- Exam eligibility overview
```

## RESTful Design Principles

```admonish note "RESTful design"
All controllers follow Rails conventions:
- Use standard REST actions where possible.
- Nest resources appropriately (`lectures/:id/campaigns`).
- Use member vs collection routes correctly.
- Render HTML and Hotwire responses (Turbo Frames/Streams); no public JSON API.
```

## Authorization

```admonish warning "Authorization"
Controllers integrate with CanCanCan abilities:
- `load_and_authorize_resource` for standard CRUD.
- Custom checks for special actions (allocation, grading).
- Role-based access (student, tutor, teacher, editor, admin).
```

## Error Handling

```admonish bug "Error handling"
Controllers should handle:
- ActiveRecord validation errors (display form errors).
- Authorization failures (redirect with flash message).
- Background job failures (show status and retry option).
- Constraint violations (e.g., deleting campaign with registrations).
```
