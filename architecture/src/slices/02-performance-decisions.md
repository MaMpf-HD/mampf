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

## E-2.4 · An achievement is "ungraded" when no grade text exists at all

> **Is absence of a grade the right definition of "not yet decided" for an
> achievement?**

**As built.** `achievement_ids_ungraded` rejects achievements whose assessment
has a participation with a non-blank `grade_text`; everything else counts as
ungraded. `achievement_ids_met` independently checks the threshold.

**Code.** [`achievement_ids_ungraded`][c2-ungraded] ·
[`achievement_ids_met`][c2-met]

**Example.** The achievement "Blackboard presentation" is boolean.

- Klara's participation has `grade_text = "pass"` → met
- Lena's has `grade_text = "fail"` → graded, **not** ungraded, and not met
- Mia has no participation row, or one with a blank grade → **ungraded**

That third case is exactly what slice 3 turns into `:inconclusive` and hence a
pending certification.

**Why it matters.** A student who simply was never entered is treated the same as
one whose grading is genuinely outstanding. Since a lecture-wide seed creates
participations for all members
([E-2.7](#e-27--adding-an-achievement-seeds-a-participation-for-every-member)),
the usual case is a blank grade rather than a missing row — but both land in the
same bucket.

**Status:** confirm — the branches are covered by
`computation_service_spec`.

---

## E-2.5 · Records are recomputed wholesale, not incrementally

> **Should any change to an achievement's threshold trigger a full recomputation
> for the entire lecture?**

**As built.** An `after_commit` on `Achievement` calls
`compute_and_upsert_all_records!` for the lecture whenever `threshold` or
`value_type` changed, or the achievement was destroyed.

**Code.** [the trigger condition][c2-shouldinvalidate] ·
[the recompute][c2-invalidate] · [`compute_and_upsert_all_records!`][c2-all]

**Example.** A lecture has 600 members. A teacher lowers an achievement's
threshold from 60 to 50.

- every one of the 600 records is recomputed and upserted, in batches of 100
- this happens synchronously, inside the request that saved the achievement

**Why it matters.** Correctness is bought with a synchronous full sweep. The
service is written for it — it prefetches participations and task points to avoid
N+1 — but the cost still scales with lecture size on a user-facing save. Editing
an achievement's *title* is correctly exempt; only threshold and type trigger it.

**Status:** verify.

---

## E-2.6 · `Record#stale?` is advisory and unused downstream

> **Is a seven-day age threshold the right notion of staleness, given that slice
> 3 defines its own?**

**As built.** `Record#stale?` returns true when `computed_at` is older than
`STALE_THRESHOLD = 7.days`.

**Code.** [`stale?`][c2-stale]

**Example.** Slice 3's `Certification.stale` scope asks a completely different
question: is `records.computed_at` newer than `certs.certified_at`? That
comparison never consults `Record#stale?`, and a record can be "stale" by the
seven-day rule while a certification based on it is perfectly current — or the
reverse.

**Why it matters.** Two unrelated definitions of the same word live one slice
apart. Whichever is shown in the UI, a reader will assume they agree.

**Status:** verify · worth renaming one of the two.

---

## E-2.7 · Adding an achievement seeds a participation for every member

> **Should creating an achievement immediately create a row for every enrolled
> student?**

**As built.** `Achievement#setup_assessment` runs on create (behind the
`assessment_grading` flag), calls `ensure_assessment!` and then seeds
participations for all `lecture.members`.

**Code.** [`setup_assessment`][c2-setup] ·
[`Lecture#sync_student_performance_for_members!`][c2-sync] ·
[the marking table][c2-marking]

**Example.** A teacher adds "Blackboard presentation" to a lecture with 600
members. 600 participation rows are inserted immediately, via slice 1's
`insert_all` path. Students who enrol *later* get no row from this hook —
`Lecture#sync_student_performance_for_members!`, in this same slice, covers them.

**Why it matters.** The rows are what the grading surface is made of.
`AchievementMarkingTableComponent` iterates the participations, and its template
opens with `<% if any_participations? %>` — with no rows it shows
"no participations" and offers nothing to click. Since an achievement has no
submission event that could create a row on the way past, lazy creation here
would mean the first row could never come into being.

Note it is *not* needed for the computation:
[E-2.4](#e-24--an-achievement-is-ungraded-when-no-grade-text-exists-at-all)
treats a missing row and a blank grade identically, so the performance records
would come out the same either way.

The cost is a bulk write on a single form submission, and 600 rows that may never
be graded.

~~~admonish note "This departs from the architecture book, on purpose"
The book states in four places that participations are created **lazily, not
eagerly** — "Does not eagerly seed participations", "Ensure participations are
created lazily, not eagerly". That is written about *assignments*, where a
submission creates the row, and assignments do follow it. For **exams** the book
wants the opposite ("All exam participations exist *before* grading begins").

Achievements are not covered either way, and they have no submission event — so
the rule cannot apply as written. Seeding up front is the only shape that yields
a usable grading table.
~~~

**Status:** confirm.

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
| E-2.4 | "Ungraded" = no grade text at all | settled |
| E-2.5 | Threshold change ⇒ synchronous full-lecture recompute | reconstructed |
| E-2.6 | `Record#stale?` is a second, unrelated definition of stale | reconstructed |
| E-2.7 | Creating an achievement seeds every member | settled |
| E-2.8 | Non-members skipped; their records are never cleaned up | reconstructed |
| E-2.9 | Percentage nil when unmeasurable, flattened to 0 downstream | reconstructed |

**E-2.5 deserves the most attention.** Changing a threshold recomputes every
record in the lecture, synchronously, in the request that saved the rule.

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
