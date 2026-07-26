# Slice 2 — Decisions

```admonish question "How to read this page"
Nine places where slice 2 makes a choice that cannot be read off the diff. Each
entry leads with a **question for the reviewer**.

**Status** is one of **settled** (rationale and test exist), **reconstructed**
(intent inferred; the author should confirm) or **open** (needs a decision).
```

```admonish tip "About the code links"
Permalinks are pinned to commit
[`73031867`](https://github.com/MaMpf-HD/mampf/commit/730318679fe08d1c981f169de965fb91461dcff7),
the tip of `muesli-02-performance-achievements`. All URLs live in one block at
the end of the file.
```

---

## E-2.1 · Only assignments count towards points

> **Should talks, exams and achievements contribute nothing to a student's point
> total?**

**As built.** The service's `assessments` scope filters
`assessable_type: "Assignment"`. Every other assessable is invisible to the
point aggregation.

**Code.** [the `assessments` scope][c2-assessments] ·
[`aggregate_from_prefetched`][c2-aggregate]

**Example.** *Analysis I* has ten homework assignments (120 points), one graded
talk (20 points) and, from slice 4 on, an exam.

- Hannah scores 90 on homework and 20 on her talk
- her record shows **90 of 120**, 75 % — the talk is absent from both numbers
- an eligibility rule of "at least 50 %" therefore judges homework only

**Why it matters.** The term "performance record" suggests everything a student
did, and a teacher configuring a percentage threshold will reasonably assume it
covers all point-bearing work. Once slice 4 adds exams as `Pointable`, this
becomes load-bearing: exam points will silently not count towards eligibility for
the next exam.

**Alternative.** Include every `Pointable` assessable, or make the set
configurable per rule.

**Status:** reconstructed.

---

## E-2.2 · Exempt participations shrink the denominator

> **Should an exempted assignment reduce the maximum points rather than count as
> zero?**

**As built.** `aggregate_from_prefetched` collects the assessment IDs of
`exempt` participations and removes those assessments from the `points_max` sum.
`reviewed` participations contribute to `points_total`.

**Code.** [`aggregate_from_prefetched`][c2-aggregate] ·
[`effective_max`][c2-effmax]

**Example.** Ten assignments, 12 points each (120 total). Ian is exempted from
two on medical grounds and scores 84 on the remaining eight.

- exempt assessments drop out of the maximum → `points_max` = **96**
- `points_total` = 84 → **87.5 %**

Had exemption counted as zero, he would sit at 70 % and might fail a 75 %
threshold he was never meant to be measured against.

**Why it matters.** This is the fair reading and almost certainly the intent —
but it means two students can have percentages computed against different
denominators, so the percentage is not comparable across students, only against
a threshold.

**Status:** reconstructed.

---

## E-2.3 · Only `reviewed` participations contribute points

> **Should a graded-but-not-yet-reviewed participation count for nothing?**

**As built.** Points are summed over participations whose status is `reviewed`.
`pending` contributes nothing to the total but is *not* removed from the
maximum.

**Code.** [`aggregate_from_prefetched`][c2-aggregate]

**Example.** Jonas hands in all ten assignments. Nine are graded; the tenth sits
ungraded at the tutor's.

- `points_total` counts nine → say 96
- `points_max` still counts all ten → 120
- record shows **80 %**

His percentage is depressed purely by the tutor's backlog, and nothing in the
record distinguishes "scored badly" from "not marked yet".

**Why it matters.** Slice 3 turns this percentage into an eligibility decision.
An unfinished grading queue therefore looks exactly like poor performance. Note
that slice 3 handles this carefully for *achievements* (there is an explicit
`ungraded` state) but not for points.

**Status:** reconstructed · consider whether the record should expose an
"ungraded points" figure the way it exposes ungraded achievements.

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

**Status:** settled — the branches are covered by
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

**Status:** reconstructed.

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

**Status:** reconstructed · worth renaming one of the two.

---

## E-2.7 · Adding an achievement seeds a participation for every member

> **Should creating an achievement immediately create a row for every enrolled
> student?**

**As built.** `Achievement#setup_assessment` runs on create (behind the
`assessment_grading` flag), calls `ensure_assessment!` and then seeds
participations for all `lecture.members`.

**Code.** [`setup_assessment`][c2-setup]

**Example.** A teacher adds "Blackboard presentation" to a lecture with 600
members. 600 participation rows are inserted immediately, via slice 1's
`insert_all` path.

Students who enrol *later* get no row from this hook — slice 3's
`Lecture#sync_student_performance_for_members!` covers that separately.

**Why it matters.** It makes "ungraded" the well-defined default state for every
student rather than an absence, which is what makes
[E-2.4](#e-24--an-achievement-is-ungraded-when-no-grade-text-exists-at-all)
behave predictably. The cost is a bulk write on a single form submission.

**Status:** settled.

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

**Status:** reconstructed.

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

**Status:** reconstructed.

---

## Summary

| # | Decision | Status |
|---|---|---|
| E-2.1 | Only assignments count towards points | reconstructed |
| E-2.2 | Exempt shrinks the denominator | reconstructed |
| E-2.3 | Only `reviewed` contributes; ungraded depresses the percentage | reconstructed |
| E-2.4 | "Ungraded" = no grade text at all | settled |
| E-2.5 | Threshold change ⇒ synchronous full-lecture recompute | reconstructed |
| E-2.6 | `Record#stale?` is a second, unrelated definition of stale | reconstructed |
| E-2.7 | Creating an achievement seeds every member | settled |
| E-2.8 | Non-members skipped; their records are never cleaned up | reconstructed |
| E-2.9 | Percentage nil when unmeasurable, flattened to 0 downstream | reconstructed |

**E-2.1 and E-2.3 deserve the most attention.** Both silently shape the number
that slice 3 turns into an admission decision: the first by excluding whole
categories of work, the second by making an unfinished grading queue
indistinguishable from poor performance.

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 73031867, the tip of                -->
<!-- muesli-02-performance-achievements. To re-pin, replace the SHA.     -->
<!-- ------------------------------------------------------------------ -->

[c2-assessments]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L49-L54
[c2-aggregate]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L71-L87
[c2-effmax]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L164-L166
[c2-met]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L107-L122
[c2-ungraded]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L124-L133
[c2-all]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L24-L45
[c2-forone]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L13-L22
[c2-pct]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/computation_service.rb#L168-L172
[c2-stale]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/student_performance/record.rb#L10-L12
[c2-setup]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/achievement.rb#L64-L67
[c2-shouldinvalidate]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/achievement.rb#L54-L56
[c2-invalidate]: https://github.com/MaMpf-HD/mampf/blob/730318679fe08d1c981f169de965fb91461dcff7/app/models/achievement.rb#L58-L62
