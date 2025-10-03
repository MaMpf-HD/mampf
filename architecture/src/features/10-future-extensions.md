# Future Extensions & Roadmap

Collection of potential enhancements and ideas for future development.

```admonish note "Implementation Status"
The core architecture documented in Chapters 1-9 represents the planned baseline. This chapter lists potential future enhancements.
```

---

## 1. Allocation Algorithm

- CP-SAT strategy (fairness tiers, exclusions, group pairing)
- Soft penalties (time-of-day preferences, instructor load balancing)
- Diversity/quota constraints (track distribution, campus location)
- Multi-round capacity release (phased seat allocation)
- Waitlist modeling (flow network with priority costs)
- Multi-campaign global optimization (joint tutorial + lab balancing)
- Solver audit trail (persist inputs/outputs as JSON for debugging)
- Alternative algorithm comparison (min-cost flow vs. CP-SAT benchmarks)

---

## 2. Registration & Policy System

- Policy trace persistence (store evaluation results for audit)
- User-facing explanations (API endpoint showing why ineligible)
- Rate limiting for FCFS hotspots
- Bulk eligibility preview (matrix: users × policies)
- Policy simulation mode (test changes without affecting real data)

---

## 3. Roster Management

- Batch operations (CSV import/export)
- Capacity forecasting and rebalancing suggestions
- Automatic load balancing (heuristic-based)
- Enhanced change history UI

---

## 4. Assessment & Grading

- Inline annotation integration (external service)
- Rubric templates per task (structured criteria + auto-sum)
- Late policy engine (configurable penalty computation)
- Task dependencies (unlock logic)
- Peer review workflows

### Multiple Choice Extensions

- MC question bank (reusable question library)
- Randomized exams (per-student variants)
- Statistical analysis (item difficulty, discrimination indices)

---

## 5. Exam Eligibility

- Multiple concurrent policies (AND/OR logic expression builder)
- Incremental recompute (listen to grade changes, trigger automatic update)
- Eligibility preview for students (before registration opens)
- Custom formula DSL (complex eligibility calculations)

---

## 6. Grade Schemes

- Percentile buckets (automatic equal-size grouping)
- Curve normalization (mean target, standard deviation scaling)
- Piecewise linear editor with live histogram preview
- Custom function DSL (arbitrary grade computations)
- Course-level aggregation (weighted composition across assessments)
- Pass/fail rules (configurable requirements)
- Bonus points system (extra credit with caps)

---

## 7. Analytics & Reporting

- Student grade projection ("what if" calculator)
- Progress tracking dashboard
- Historical trend comparison
- Allocation satisfaction metrics (average preference rank achieved)
- Grade distribution analysis (variance heatmaps, outliers)
- Capacity utilization tracking
- Tutor workload reports
- CSV export with snapshot versioning
- JSON API (read-only endpoints)
- Materialized views for performance

---

## 8. Operational Tools

- Automatic integrity auditor (scheduled job checking invariants)
- Integrity dashboard (real-time constraint violations)
- Performance metrics (query times, job durations, failure rates)
- mdBook link checker CI integration
- Chaos testing (inject perturbations in test environment)
- Solver visualizer (export flow network to DOT/Mermaid)
- Benchmark harness (compare algorithm performance)

---

## 9. Performance & Scalability

- Incremental solver updates (delta changes for preference edits)
- Eligibility caching (memoize with versioned keys)
- Points total caching (invalidate per TaskPoint write)
- Database sharding strategy

---

## 10. API & Extensibility

- GraphQL endpoint (read-only access to allocations/grades)
- REST API (standard CRUD for integrations)
- Webhooks (events: finalize, grade published, eligibility change)
- Internal event bus (decouple reactions)
- Plugin system (custom policy types, grade schemes)

---

## 11. Security & Compliance

- Policy audit trail (tamper-evident logs)
- PII minimization (anonymize exports, configurable retention)
- GDPR compliance (data export, deletion, consent management)

---

## 12. Developer Experience

- Reference seed script (generate realistic test data)
- Scenario generator (complex allocation/grading scenarios)
- Solver visualizer (export flow network to DOT/Mermaid)
- Benchmark harness (compare algorithm performance)
- Documentation sync (CI check for broken mdbook links)

---

## 13. UI/UX

- Real-time capacity counters (WebSocket updates)
- Drag-drop preference ordering with validation
- Grade histogram overlay (scheme preview)

---

## 14. Migration & Cleanup

- Dual-write (new + legacy systems)
- Backfill historical data
- Read switch with parity monitoring
- Remove deprecated code/columns
- Legacy eligibility flags cleanup
- Manual roster seeding code removal
- Obsolete submission routing cleanup

---

## 15. Research Opportunities

- Fairness metrics (study allocation algorithm properties)
- Optimal grading curves (per-subject analysis)
- Predictive modeling (early intervention for at-risk students)
- Learning analytics (engagement vs. outcomes correlation)
