# Slice 4 — Decisions

```admonish question "How to read this page"
Two choices this slice makes where the code shows *what* happens but not why
that option was picked or what it costs elsewhere. Each entry leads with a
**question for the reviewer** and then answers it the way the branch currently
does — they aim your reading rather than replace it.

**Status** is one of **settled** (rationale and test exist), **reconstructed**
(intent inferred; the author should confirm) or **open** (needs a decision).
```

```admonish tip "About the code links"
Permalinks are pinned to commit
[`cb300a0c`](https://github.com/MaMpf-HD/mampf/commit/cb300a0c1721249a879590bb00d2c92f3855d944),
the tip of `muesli-04-exam-core`. All URLs live in one block at the end of the
file.
```

---

## E-4.8 · The exam lifecycle is derived, not stored

> **Should the exam's phase be computed from campaign status and date rather
> than being a column?**

**As built.** `status_phase` returns `:draft`, `:registration_open`,
`:registration_closed`, `:finalized`, `:conducted`, `:grading` or `:graded`,
computed from the campaign's status and the exam date.

**Code.** [`status_phase`][c4-phase]

**Example.** An exam whose campaign is `completed` and whose date is yesterday
reports `:conducted` — without anything having been written to the exam row when
the clock passed midnight.

**Why it matters.** Nothing can drift out of sync, and no migration is needed
when a phase is added. The cost is that the phase cannot be queried in SQL: any
"show me all exams awaiting grading" list has to load and ask each one.

**Status:** reconstructed.

---

## E-4.10 · Exams carry the full assessment stack from day one

> **Should an exam be `Pointable` and `Gradable` already in this slice, although
> grading only arrives in slice 5?**

**As built.** `Exam` includes `Registration::Registerable`,
`Rosters::Rosterable`, `Assessment::Pointable` and `Assessment::Gradable`, and
an `after_create` calls `setup_assessment` behind the `assessment_grading` flag.

**Code.** [the concern stack and hooks][c4-concerns]

**Example.** Creating an exam immediately produces an `Assessment` with
`requires_points: true`, ready for tasks — even though no UI in slice 4 grades
anything. Slice 5 then only adds the grade scheme on top, without touching
`Exam`.

**Why it matters.** It keeps slice 5's diff small and means an exam is never in
a state where it has a roster but no gradebook. The cost is that slice 4 creates
rows for a feature it does not yet expose, which makes the slice boundary softer
than the PR title suggests.

**Status:** settled.

---

## Summary

| # | Decision | Status |
|---|---|---|
| E-4.8 | Lifecycle derived, not stored | reconstructed |
| E-4.10 | Full assessment stack included from the start | settled |

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 77565064, the tip of                -->
<!-- muesli-04-exam-core. To re-pin, replace the SHA below.              -->
<!-- ------------------------------------------------------------------ -->

[c4-phase]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L106-L123
[c4-concerns]: https://github.com/MaMpf-HD/mampf/blob/cb300a0c1721249a879590bb00d2c92f3855d944/app/models/exam.rb#L19-L38
