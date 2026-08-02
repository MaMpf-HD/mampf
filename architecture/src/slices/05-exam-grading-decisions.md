# Slice 5 — Decisions

```admonish question "How to read this page"
Nine choices this slice makes where the code shows *what* happens but not why
that option was picked or what it costs elsewhere. Each entry leads with a
**question for the reviewer** and then answers it the way the branch currently
does — they aim your reading rather than replace it.

**Status** is one of **settled** (rationale and test exist), **reconstructed**
(intent inferred; the author should confirm) or **open** (needs a decision).
```

```admonish tip "About the code links"
Permalinks are pinned to commit
[`25b9597e`](https://github.com/MaMpf-HD/mampf/commit/25b9597ec69a791d3dd8ae841bae7c35d7c460f4),
the tip of `muesli-05-exam-grading`. All URLs live in one block at the end of
the file.
```

---

## E-5.1 · Re-applying a scheme spares already-graded participations

> **Should a second application only fill in the gaps rather than recompute
> everything?**

**As built.** `apply!` branches on `already_applied?`. The first run targets all
reviewed participations; every later run targets only those **without** a grade.

**Code.** [`apply!`][c5-apply]

**Example.** A scheme is applied to 200 exams. The teacher then corrects Quinn's
grade by hand from 2.7 to 2.3 (a borderline case decided in conference). Two
students are graded late and become reviewed afterwards. The teacher hits
"apply" again.

- the two late participations get their computed grades
- **Quinn keeps 2.3** — the manual correction survives
- the other 199 are untouched

**Why it matters.** It makes the button safe to press twice, which matters when
grading trickles in. The flip side: after a manual correction, the stored grades
no longer all follow the scheme, and nothing marks which ones deviate.

**Status:** reconstructed · consider surfacing "n grades deviate from the active
scheme".

---

## E-5.3 · Missing points are a 5.0, not an error

> **Should a reviewed participation with no `points_total` silently become a
> failing grade?**

**As built.** `compute_grade_for` returns 5.0 when `points_total` is nil, and
again when a percentage scheme finds `effective_total_points` nil or zero.

**Code.** [`compute_grade_for`][c5-compute]

**Example.** Sam's participation was set to `reviewed` but no task points were
ever entered, so `points_total` is nil.

- the scheme is applied → Sam gets **5.0**
- had the same participation stayed `pending`, it would not have been targeted at
  all

So a status set one click too early converts into a failing grade, with no
warning in the preview.

**Why it matters.** The three cases "scored zero", "not marked yet" and "no
scheme applicable" all produce the identical stored outcome.

**Status:** reconstructed.

---

## E-5.4 · An applied scheme is frozen

> **Should a scheme become immutable once it has been applied, except for
> deactivating it?**

**As built.** `immutable_when_applied` rejects any update once `applied_at_was`
is present, except to `active`, `applied_at`, `applied_by_id` and `updated_at`.

**Code.** [`immutable_when_applied`][c5-immutable]

**Example.** A teacher applies a scheme, then wants to lower the 4.0 boundary by
two points after complaints.

- editing the existing scheme is refused
- the supported path is to deactivate it and create a new one, then apply that

The old scheme therefore survives as a record of what produced the original
grades.

**Why it matters.** It is what makes `version_hash` meaningful as an audit
reference — a grade can be traced to a mapping that provably has not changed
since. The cost is that every correction produces a new row.

**Status:** settled.

---

## E-5.5 · The version hash ignores band order

> **Should reordering bands without changing them count as the same scheme?**

**As built.** `compute_hash` MD5s the config after `deep_sort_keys`, which sorts
hash keys recursively — so two configs that differ only in key order hash
identically.

**Code.** [`compute_hash`][c5-hash] · [`deep_sort_keys`][c5-deepsort]

**Example.** A teacher rebuilds the same scheme in the UI and the band objects
come back as `{"grade": …, "min_points": …}` instead of
`{"min_points": …, "grade": …}`.

- the JSON differs byte for byte
- the hash is **identical**, so the scheme is recognised as unchanged

Note the sort is applied to hash *keys*, not to the bands array — reordering the
bands themselves does change the hash, even though the mapping they describe is
the same.

**Why it matters.** The hash is the identity used to tell "this grade came from
that mapping". It is stable against serialisation noise but not against a
semantically irrelevant reordering of the band list.

**Status:** reconstructed.

---

## E-5.6 · Reviewed participations cannot be marked absent

> **Should the transition from reviewed to absent or exempt be refused
> outright?**

**As built.** `validate_not_reviewed!` raises `InvalidTransitionError` with the
message "would discard grading data".

**Code.** [`mark_absent` / `mark_exempt`][c5-absence] ·
[`validate_not_reviewed!`][c5-nottransition]

**Example.** Tim is graded, then turns out to have been ill and produces a
certificate. Marking him exempt is:

- refused with an exception
- the supported route is to clear his grading data first

Read this as a rule the code already enforces, not as a screen that exists: the
module holding both transitions is not yet called from anywhere, so in this
slice the guard protects a path only its own spec can take. The write path is
being built on `muesli/tutor-grading-view`.

**Why it matters.** Both transitions null `submitted_at`, so allowing them from
`reviewed` would strand a grade on a participation that claims nothing was
handed in. Refusing is the safe direction, but the correct workflow — how to
retract a grade — is not provided by this slice.

**Status:** settled — the rule; the write path itself is a to-do elsewhere.

---

## E-5.7 · One active scheme per assessment, and it may be none

> **Should an assessment be allowed to have several schemes as long as only one
> is active?**

**As built.** A uniqueness validation scoped to `assessment_id` with
`conditions: -> { where(active: true) }`, plus a partial unique index in the
migration. Inactive schemes accumulate freely.

**Code.** [the uniqueness validation][c5-unique]

**Example.** An exam ends up with three schemes: the first draft (inactive), the
one that was applied (inactive after being superseded), and the current active
one. The history of what was tried is preserved, and only one can be in force.

**Why it matters.** It is what makes [E-5.4](#e-54--an-applied-scheme-is-frozen)
workable — corrections create rows rather than mutating them. Nothing prunes the
old ones.

**Status:** settled.

---

## E-5.8 · Band values are validated for shape, and now for type

> **Is validating that all bands use the same threshold key, plus that values
> are numeric, sufficient?**

**As built.** `validate_banded_config` requires a non-empty `bands` array, a
consistent threshold key across all bands (`min_points` **xor** `min_pct`), a
present `grade` on every band, and — since the XSS fix — that grade and
threshold are numeric.

**Code.** [`validate_banded_config`][c5-bandconfig]

**Example.** These are rejected: an empty band list; a mix of `min_points` and
`min_pct`; a band without a grade; a grade of
`<img src=x onerror=alert(1)>`.

These are **not** rejected: overlapping bands; gaps between bands; a band list
with no 5.0 fallback; thresholds that exceed the assessment's maximum points.

**Why it matters.** The shape is guarded, the *coverage* is not. A scheme whose
lowest band starts at 10 points leaves everyone below 10 falling through to the
`5.0` default in `compute_grade_for` — which happens to be correct, but by
accident rather than by construction.

**Status:** reconstructed · the numeric check is settled (three specs); the
coverage gap is unaddressed.

---

## E-5.9 · `two_point_auto` spreads grades evenly and refuses narrow ranges

> **Is an even spread between "passing" and "excellence" the right default
> scheme generator?**

**As built.** The ten passing grades are spread linearly between the two given
point values, each boundary rounded to `points_step`. The method raises when the
range is too narrow for the step, when boundaries would collapse, or when
excellence exceeds the maximum.

**Code.** [`two_point_auto`][c5-twopoint]

**Example.** Passing 24, excellence 54, step 1 → nine intervals of 3.33 points,
rounded to whole points: 24, 27, 30, 33, 37, 40, 44, 47, 51, 54. A 5.0 band from
0 is prepended because passing is above zero.

With passing 24 and excellence 30 the same call raises: nine boundaries cannot
fit into six points at step 1.

**Why it matters.** It encodes a pedagogical convention — equal point intervals
per grade step — as the default. Raising rather than silently collapsing
boundaries is the right call, but the errors are `ArgumentError` with English
messages, so a controller must translate them.

**Status:** reconstructed.

---

## E-5.10 · Grading is attached to the assessment, not the exam

> **Should grade schemes be usable for assignments too, rather than being
> exam-specific?**

**As built.** `GradeScheme belongs_to :assessment`, and a validation requires
the assessable to be both `Pointable` and `Gradable`.

**Code.** [`assessable_must_be_pointable_and_gradable`][c5-pointgrad]

**Example.** Because `Exam` includes both concerns (slice 4) and `Assignment`
includes `Pointable`, an exam can carry a scheme immediately. An assignment
cannot until it also becomes `Gradable` — the validation is what states that
requirement rather than leaving it implicit.

**Why it matters.** It keeps slice 5 free of exam-specific code and makes
"gradable" a checkable property instead of a convention. The trade-off is that
the grading UI reached through the exam is really an assessment feature, so
finding it in the code means going through the polymorphic association.

**Status:** settled.

---

## Summary

| # | Decision | Status |
|---|---|---|
| E-5.1 | Re-apply only fills gaps; manual grades survive | reconstructed |
| E-5.3 | Missing points ⇒ 5.0, indistinguishable from a real fail | reconstructed |
| E-5.4 | An applied scheme is frozen | settled |
| E-5.5 | Version hash ignores key order, not band order | reconstructed |
| E-5.6 | Reviewed cannot become absent/exempt | settled |
| E-5.7 | One active scheme, inactive ones accumulate | settled |
| E-5.8 | Band shape and types validated; coverage is not | reconstructed |
| E-5.9 | `two_point_auto` spreads evenly, raises on narrow ranges | reconstructed |
| E-5.10 | Grading hangs off the assessment, not the exam | settled |

**E-5.3 is the one to read first**: three quite different situations — scored
zero, not marked yet, no scheme applicable — all end up stored as the same 5.0.

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 25b9597e, the tip of                -->
<!-- muesli-05-exam-grading. To re-pin, replace the SHA below.           -->
<!-- ------------------------------------------------------------------ -->

[c5-apply]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme_applier.rb#L69-L115
[c5-compute]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme_applier.rb#L117-L135
[c5-immutable]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L60-L67
[c5-hash]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L24-L28
[c5-deepsort]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L86-L95
[c5-absence]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/absence_handling.rb#L5-L20
[c5-nottransition]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/absence_handling.rb#L24-L30
[c5-unique]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L11-L12
[c5-bandconfig]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L102-L139
[c5-twopoint]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L30-L56
[c5-pointgrad]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L69-L77
