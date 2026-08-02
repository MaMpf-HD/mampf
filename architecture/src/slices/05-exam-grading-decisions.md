# Slice 5 — Decisions

```admonish question "How to read this page"
Three choices this slice makes where the code shows *what* happens but not why
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
| E-5.8 | Band shape and types validated; coverage is not | reconstructed |
| E-5.9 | `two_point_auto` spreads evenly, raises on narrow ranges | reconstructed |
| E-5.10 | Grading hangs off the assessment, not the exam | settled |

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 25b9597e, the tip of                -->
<!-- muesli-05-exam-grading. To re-pin, replace the SHA below.           -->
<!-- ------------------------------------------------------------------ -->

[c5-bandconfig]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L102-L139
[c5-twopoint]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L30-L56
[c5-pointgrad]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L69-L77
