# Slice 5 — Decisions

```admonish question "How to read this page"
One choice this slice makes where the code shows *what* happens but not why
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
| E-5.10 | Grading hangs off the assessment, not the exam | settled |

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 25b9597e, the tip of                -->
<!-- muesli-05-exam-grading. To re-pin, replace the SHA below.           -->
<!-- ------------------------------------------------------------------ -->

[c5-pointgrad]: https://github.com/MaMpf-HD/mampf/blob/25b9597ec69a791d3dd8ae841bae7c35d7c460f4/app/models/assessment/grade_scheme.rb#L69-L77
