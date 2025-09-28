# Future Extensions & Roadmap

Curated list of planned or potential enhancements, grouped by domain.

## 1. Solver & Allocation
Near-term
- CP-SAT strategy (fairness tiers, exclusions, group pairing).
- Soft penalties (time-of-day, instructor load).
- Diversity / quota constraints (e.g., track, campus).
Medium
- Multi-round capacity release (phased seats).
- Waitlist modeling (flow with priority costs).
Long-term
- Multi-campaign global optimization (joint tutorial+lab balancing).
- Audit trail for solver inputs/outputs (persisted JSON).

## 2. Registration & Policies

- Policy trace persistence & user-facing explanation endpoints.
- Rate limiting / throttling for FCFS hotspots.
- Bulk eligibility preview UI (matrix: user × policy).
- A/B style alternative policy sets (simulate impact).

## 3. Rosters & Administration

- Batch roster operations (CSV diff apply).
- Capacity forecasting (suggest rebalancing moves).
- Automatic balancing script (soft heuristic before manual tweaks).
- Roster change history model (immutable log beyond application logs).

## 4. Assessments & Grading

- Full Submittable concern (Assessment / Task polymorphic) replacing legacy assignment_id routing.
- Inline annotation integration (external service).
- Rubric templates per Task (structured criteria & auto-sum).
- Late policy engine (penalties computation abstraction).
- Task dependency graph (unlock logic).

## 5. Exam Eligibility & Grading Schemes

- Multiple concurrent eligibility policies (AND/OR logic expression builder).
- Incremental eligibility recompute triggers (listen to TaskPoint changes).
- Advanced grade schemes:
	- Parametric percentile buckets (automatic equal-size grouping).
	- Curve normalization (mean target, std deviation scaling).
	- Piecewise linear re-scaling editor with live histogram.
- CourseGradeRecord aggregator (weighted composition + pass/fail rules).

## 6. Analytics & Reporting

- Materialized views / summary tables for performance.
- Export pipelines (CSV, JSON API) with snapshot version tags.
- Instructor dashboards: variance heatmaps, allocation satisfaction metrics (average preference rank).
- Student-facing “what if” grade projection.

## 7. Integrity & Ops
- Automatic integrity auditor (scheduled job + report page).
- mdBook link checker CI integration.
- Background job instrumentation (duration, failure rate).
- Chaos test mode for solver (inject capacity perturbations pre-prod).

## 8. Performance / Scaling
- Incremental solver rebuild (delta arcs) for minor preference edits pre-deadline.
- Caching layers:
	- Eligibility record memoization (versioned key).
	- Points total cache invalidated per TaskPoint write.
- Sharding strategy outline once user_registrations volume > threshold.

## 9. API & Extensibility
- Public GraphQL / REST endpoints (read-only) for allocation & grades.
- Webhooks on finalize!, grade published, eligibility change.
- Event bus (internal) to decouple downstream reactions (notifications, analytics).

## 10. Security & Compliance
- Policy evaluation audit trail (tamper-evident).
- PII minimization in exported artifacts.
- Configurable data retention (auto-archive old TaskPoints / submissions).

## 11. Developer Tooling
- Reference seed script generating synthetic campaigns & grading scenarios.
- Solver scenario visualizer (graph export to DOT / Mermaid).
- Benchmark harness comparing strategies (min_cost_flow vs cp_sat) on sample loads.

## 12. UI Enhancements
- Real-time capacity counters (WebSocket).
- Preference rank drag/drop ordering with immediate validation.
- Grade distribution histogram overlays (scheme preview).

## 13. Migration Strategy (Legacy → New)
- Step 1: Dual-write Registration::Policy & legacy eligibility flags.
- Step 2: Backfill ExamEligibilityRecords.
- Step 3: Read switch; monitor parity metrics.
- Step 4: Remove deprecated columns.

## 14. Sunset / Cleanup Targets
- Legacy policy fields on Registration::Campaign (folded into Registration::Policy table).
- Manual per-assessment roster seeds replaced by generic roster seeding service.
- Obsolete submission fields after Submittable adoption.

