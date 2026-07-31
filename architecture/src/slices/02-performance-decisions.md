# Slice 2 — Before review

```admonish question "How to use this page"
A working list, not a reviewer document. Each entry is a design point in slice 2
that still needs something from **the author** before the branch goes out for
review — agreement, a check, or a change to the code.

Entries leave this page in one of two ways: the choice is confirmed, or the code
is changed so it can be. Either way the point then moves to
[Decisions made in this slice](02-performance.md#decisions-made-in-this-slice)
on the slice page, where the reviewer finds it as background. When this page is
empty it can go.

Unlike slice 1, **every entry here is this slice's own**. The architecture book
designs the materialised record and asks for just-in-time recomputation; how much
is recomputed, what counts towards the totals, and what "ungraded" means were all
decided in the code. What the book does fix is under
[Following the architecture book](02-performance.md#following-the-architecture-book).

Each entry carries a **Test** line naming the spec that pins the behaviour, or
saying that none does. Those lines are checked against the branch, not assumed.

**Status** is what the entry still needs:
- **confirm** — intent is clear and a test pins it; agree and move on
- **cover** — intent is clear, but nothing pins it; a test has to be written
- **verify** — intent was inferred from the code; check the reading is right first
- **decide** — no discernible intent; a choice has to be made
```

```admonish tip "About the code links"
Permalinks are pinned to commit
[`b2c5529c`](https://github.com/MaMpf-HD/mampf/commit/b2c5529ce790ba9746010a37cad7e01d25c0c55b),
the tip of `muesli-02-performance-achievements`. All URLs live in one block at
the end of the file.
```

---

## E-2.8 · Non-members are silently skipped

> **Should computing a record for a non-member do nothing rather than raise?**

**As built.** `compute_and_upsert_record_for` returns early unless the user is
in `lecture.members`.

**Code.** [`compute_and_upsert_record_for`][c2-forone]

**Example.** A student leaves the lecture. A later grading callback fires for one
of their old participations.

- the guard sees they are no longer a member → returns
- their existing record is **left untouched**, not deleted

So a stale record for a departed student survives indefinitely, and slice 3's
certification dashboard may still show them.

**Why it matters.** The guard prevents creating records for outsiders, which is
right, but it also means membership changes never clean up.

**Status:** verify.

---

## E-2.9 · Percentage is nil when there is nothing to measure

> **Should a student with no maximum points have a nil percentage rather than
> zero?**

**As built.** `compute_percentage` returns `nil` when `points_max` is nil or
zero, and otherwise rounds to two decimals.

**Code.** [`compute_percentage`][c2-pct]

**Example.** A lecture has achievements but no point-bearing assignments yet, or
a student is exempt from every assignment.

- `points_max` = 0 → percentage **nil**
- slice 3's `Evaluator#points_met?` compares `(record.percentage_materialized || 0) >= rule.min_percentage`
- so nil becomes **0** at that point, and any percentage threshold fails

A student exempted from everything therefore fails a percentage rule, while the
same student under an absolute-points rule also fails (0 points). Only a rule
with no threshold admits them.

**Why it matters.** Nil is the honest value — "not measurable" is not "zero
percent" — but the consumer flattens it to zero, so the distinction is lost
exactly where it would matter.

**Status:** verify.

---

## Summary

| # | Decision | Status |
|---|---|---|
| E-2.8 | Non-members skipped; their records are never cleaned up | reconstructed |
| E-2.9 | Percentage nil when unmeasurable, flattened to 0 downstream | reconstructed |

**E-2.8 deserves the most attention.** A record left behind by somebody who has
left the lecture is never cleaned up, and nothing downstream expects one.

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 73031867, the tip of                -->
<!-- muesli-02-performance-achievements. To re-pin, replace the SHA.     -->
<!-- ------------------------------------------------------------------ -->

[c2-assessments]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/computation_service.rb#L49-L54
[c2-aggregate]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/computation_service.rb#L71-L87
[c2-met]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/computation_service.rb#L107-L122
[c2-ungraded]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/computation_service.rb#L124-L133
[c2-all]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/computation_service.rb#L24-L45
[c2-forone]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/computation_service.rb#L13-L22
[c2-pct]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/computation_service.rb#L164-L168
[c2-stale]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/student_performance/record.rb#L10-L12
[c2-setup]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/achievement.rb#L64-L67
[c2-sync]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/lecture.rb#L866-L877
[c2-marking]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/frontend/student_performance/achievements/components/achievement_marking_table_component.rb#L52-L58
[c2-shouldinvalidate]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/achievement.rb#L54-L56
[c2-invalidate]: https://github.com/MaMpf-HD/mampf/blob/b2c5529ce790ba9746010a37cad7e01d25c0c55b/app/models/achievement.rb#L58-L62
