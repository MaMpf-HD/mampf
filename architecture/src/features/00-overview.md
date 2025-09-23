# Overview

A high‑level map of the architecture proposed for the integration of MÜSLI into MaMpf. Each later layer depends only on stable persisted results from earlier phases (no hidden cross‑coupling).

```mermaid
flowchart LR
    A[Registration] --> B[Allocation];
    B --> C[Rosters];
    C --> D[Assessments & Grading];
    D --> E[Eligibility];
    E --> F[Exam Registration];
    F --> G[Reporting];
```

Core flow (see [End-to-End Workflow](06-end-to-end-workflow.md)):

1. Campaign setup & user registrations ([Registration System](02-registration-system.md))
2. Preference assignment (if needed) ([Algorithm Details](07-algorithm-details.md))
3. Allocation materialization to domain rosters ([Allocation & Rosters](03-allocation-and-rosters.md))
4. Ongoing roster administration (swaps, late adds)
5. Assessments, submissions, points & grades ([Assessments & Grading](04-assessments-and-grading.md))
6. Achievements & eligibility computation (exam gating) ([Exam Eligibility & Grading Schemes](05-exam-eligibility-and-grading-schemes.md))
7. Exam registration (policy gated) → exam assessment grading
8. Dashboards for students & staff ([Student Dashboard](student_dashboard.md), [Teacher & Editor Dashboard](teacher_editor_dashboard.md))
9. Reporting, integrity checks ([Integrity & Invariants](09-integrity-and-invariants.md))
10. Roadmap & extensibility ([Future Extensions](10-future-extensions.md))

## Book Structure

### Core Architecture

- [Overview](00-overview.md) (this)
- [Domain Model](01-domain-model.md)
- [Registration System](02-registration-system.md)
- [Allocation & Rosters](03-allocation-and-rosters.md)
- [Assessments & Grading](04-assessments-and-grading.md)
- [Exam Eligibility & Grading Schemes](05-exam-eligibility-and-grading-schemes.md)
- [End-to-End Workflow](06-end-to-end-workflow.md)
- [Algorithm Details](07-algorithm-details.md)
- [Examples & Demos](08-examples-and-demos.md)
- [Integrity & Invariants](09-integrity-and-invariants.md)
- [Future Extensions](10-future-extensions.md)

### User-Facing Applications

- [Teacher & Editor Dashboard](teacher_editor_dashboard.md)
- [Student Dashboard](student_dashboard.md)

### Project Planning

- [Implementation Plan](plan.md)

## Design Tenets

- Single source of truth per concern (e.g., confirmed assignments live in UserRegistrations + domain rosters after materialization).
- Idempotent transitions (finalize!, materialize_allocation!).
- Append/extend rather than mutate history (overrides, policy traces).
- Pluggable strategies & policies
