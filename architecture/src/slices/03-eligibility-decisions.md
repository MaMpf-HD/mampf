# Slice 3 — Decisions

```admonish question "How to read this page"
Ten choices this slice makes where the code shows *what* happens but not why
that option was picked or what it costs elsewhere. Each entry leads with a
**question for the reviewer** and then answers it the way the branch currently
does — they aim your reading rather than replace it.

**Status** is one of:
- **settled** — rationale and a test both exist
- **reconstructed** — the intent was inferred from the code; the author should confirm it
- **open** — no discernible intent; needs a decision
```

```admonish tip "About the code links"
Every entry carries a **Code** line linking to the deciding lines on GitHub.
The links are permalinks pinned to commit
[`877dc84d`](https://github.com/MaMpf-HD/mampf/commit/877dc84d5724f3a41d379ab27d9130be341a4c87),
the tip of `muesli-03-eligibility` — so they resolve even though this branch
starts from `next`, where the code does not exist yet, and they keep resolving
after the branch is merged and deleted.

They show the code **as reviewed**, not necessarily as current. Method names in
the prose are the durable reference; the line numbers belong to that one commit.
All URLs live in a single block at the bottom of this file, so re-pinning to a
later commit means editing one place.
```

---

## E-3.1 · Ungraded requirements count as "pending", not "not eligible"

> **Should a student whose required achievement is not yet graded be listed as
> _pending_ rather than _not eligible_?**

**As built.** `Evaluator#achievements_status` returns `:ungraded` when a missing
required achievement is still ungraded. That becomes the proposal
`:inconclusive`, which is stored as `Certification(status: :pending)`.

**Code.** [`achievements_status`][c-status] · [proposal mapping][c-proposal] ·
[`attributes_for_proposal`][c-attrs]

**Example.** The rule for *Analysis I* requires the achievement "Blackboard
presentation". Bob gave his presentation, but the tutor has not entered a grade
yet.

- `achievements_met_ids` does not contain it, `achievements_ungraded_ids` does
- → status `:ungraded` → proposal `:inconclusive` → `Certification(pending)`
- Bob appears in the **Open** column of the dashboard, not under *Not eligible*

**Why it matters.** If the tutor never grades it, Bob stays pending forever — and
a finalization policy that requires a *decided* certification will block the
whole campaign, not just Bob. The alternative (treat ungraded as failed) would
put the burden on the student instead of the campaign.

**Alternative.** Count ungraded as `:failed` until proven otherwise.

**Status:** settled — `evaluator_spec` covers both branches. The *rationale* is
recorded nowhere.

---

## E-3.2 · A rule must constrain something

> **Is it right that a rule with no threshold *and* no achievement is refused
> outright, rather than warned about?**

**As built.** A rule is valid only if it carries at least one criterion — a
percentage threshold, an absolute threshold, or at least one required
achievement. `Evaluator#points_met?` still falls through to `true` when no
threshold is configured, which is correct: a threshold-less rule is decided by
its achievements alone.

**Code.** [`points_met?` — the `else true` branch][c-points] ·
[`at_least_one_criterion`][c-criteria]

**Example.** *Analysis I*, threshold mode "no point threshold", required
achievement "Blackboard presentation":

- Alice has **0 of 120 points** but gave her presentation → **passed**.
  Intended — points were deliberately not part of this rule.

The same rule with the achievement box left unticked is now **rejected on save**
with *"The rule needs at least one criterion…"*. Before, it saved happily and
proposed *passed* for every student in the lecture, including one with zero
points — reachable from the UI in two clicks, with no warning anywhere.

**Why it matters.** The old failure was silent and permissive, the worst
combination for something that gates exam admission. A hard refusal is
defensible because there is already a supported way to admit everyone: leave
exam eligibility switched off. An empty rule has no second reading.

**Why refusal rather than a warning.** A warning would have to hang off "no
threshold", and at that point a legitimate achievements-only rule is
indistinguishable from an abandoned draft — the warning would fire on both and
become noise. The *combination* is the only unambiguous signal.

**Status:** settled — fixed in `121deb797` after the security audit raised it as
MS-02; covered by four model specs and one request spec.

---

## E-3.3 · Manual decisions are never overwritten automatically

> **Should a hand-set eligibility status survive a rule change untouched?**

**As built.** `CertificationsController#bulk_reevaluate` excludes
`source: :manual`. Manual rows are handled only by `bulk_confirm_manual`, which
updates `certified_at` and **not** the status.

**Code.** [the exclusion in `bulk_reevaluate`][c-reeval] ·
[`bulk_confirm_manual`][c-confirm]

**Example.** Carol submitted a medical certificate, so the teacher sets her to
*eligible* by hand (`source: :manual`). Two weeks later the threshold is raised
from 40 % to 60 %; Carol has 45 %.

- "Re-evaluate against current rule" skips her → she stays **eligible**
- She only surfaces in the *stale* counter
- "Confirm manual decisions" refreshes her timestamp and clears the warning —
  without anyone re-examining the decision

**Why it matters.** Deliberate manual overrides must not be clobbered by an
automatic sweep. The cost is that a manual *mistake* is never corrected by the
automatic path either, and the one affordance that clears the warning does not
require looking at the case.

**Alternative.** Re-evaluate manual rows too and show the divergence instead of
suppressing it.

**Status:** settled.

---


## E-3.5 · Several lectures in one policy mean OR

> **Is one passed certification enough, or must every configured lecture be
> passed?**

**As built.** OR. `StudentPerformanceHandler#evaluate` asks
`certifications.passed.exists?` across all configured lectures.

**Code.** [`evaluate` — the `passed.exists?` branch][c-handler] ·
[`Policy#lecture_ids`, incl. the legacy fallback][c-lectureids]

**Example.** An exam campaign carries a finalization policy configured with
*Analysis I* **and** *Analysis II*. Erin passed Analysis I and is still pending
in Analysis II.

- `passed.exists?` → true → policy satisfied → finalization is not blocked

If the intent was a two-semester cycle where **both** are required, Erin is
admitted although she should not be.

**Why it matters.** This is the single switch that decides admission for
multi-lecture setups, and both readings are defensible.

**Status:** settled — `finalization_guard_spec` pairs a passing and a blocking
case, and a mutation test confirms the pair distinguishes OR from AND.

---

## E-3.6 · Exactly one active rule per lecture, enforced by the database

> **Should "one active rule" be a database truth rather than an application
> convention?**

**As built.** A partial unique index,
`index_sp_rules_one_active_per_lecture` on `lecture_id WHERE active = true`.

**Code.** [the migration][c-ruleindex]

**Example.** Both `EvaluatorController#set_rule` and `RulesController#preview`
fetch the rule with `.where(lecture:, active: true).first`. Without the index a
second active row could exist and `.first` would return an arbitrary one — two
teachers could see different proposals for the same student on the same screen.
With the index that state is unreachable.

**Why it matters.** It converts a "we only ever create one" assumption into
something the database guarantees, which is what makes the unordered `.first`
safe.

**Status:** settled.

---

## E-3.7 · One `student_performance` policy per campaign, enforced twice

> **Is it right to enforce this invariant both in the model and in the
> database?**

**As built.** `Registration::Policy#single_student_performance_policy` (readable
error message) plus a partial unique index on
`registration_campaign_id WHERE kind = 2` (race safety).

**Code.** [the model validation][c-singlepolicy] · [the migration][c-policyindex]

**Example.** A teacher double-clicks "Add policy". Sequentially, the model
validation catches the second attempt and shows *"only one student performance
policy allowed"*. Concurrently — two requests interleaving before either
commits — both pass the `.exists?` check and only the index stops the second.

**Why it matters.** The application check alone is a
check-then-act race; the index alone gives an unreadable
`RecordNotUnique`. Note the index is scoped to `kind = 2` only — the same race
exists for `institutional_email` and is deliberately left alone as pre-existing
behaviour.

**Status:** settled.

---

## E-3.8 · Eligibility can only be switched off while no data exists

> **Should turning off `uses_exam_eligibility` be blocked once rules,
> certifications or policies exist?**

**As built.** `Lecture#exam_eligibility_can_be_disabled` blocks the change if any
rule, any certification, or any policy referencing the lecture exists.

**Code.** [`exam_eligibility_can_be_disabled`][c-guard]

**Example.** A teacher enables eligibility for *Analysis I*, configures a rule
and certifies 30 students. In week 10 they decide to drop the requirement and
switch the toggle off.

- → rejected with *"has existing data"*
- To proceed they must first delete the rule **and** all 30 certifications,
  which destroys the audit trail

**Why it matters.** It prevents silently orphaning decisions that students may
already have seen — at the price of no supported way back other than deletion.
Whether an archive/deactivate path is needed is a product question.

**Status:** settled — six specs cover the guard (added when a legacy config shape
turned out to bypass it).

---

## E-3.9 · `threshold_mode` is a column, not a form field

> **Is the mode worth storing, given that it could be derived?**

**As built.** An enum column on `student_performance_rules`
(`percentage` / `absolute` / `none`, default `none`). One validation keeps the
two value columns in agreement with it, so a rule can never claim a threshold it
does not carry.

**Code.** [the enum][c-mode] · [the consistency validation][c-modecheck] ·
[`apply_threshold_params`][c-applymode]

**Example.** A teacher picks "percentage" and enters 50. Stored:
`threshold_mode = percentage`, `min_percentage = 50`. Reopening the editor reads
the mode back from the row instead of guessing it.

**Alternative.** Derive the mode from whichever value column is filled, and keep
it out of the table. That works only as long as a single writer sets mode and
values together — and it fails silently when one does not: a rule with both value
columns NULL is indistinguishable from a deliberate "no point threshold", so the
form would assert a decision nobody made. An import, a console session or a
future API would be enough to produce one.

**Why it matters.** Storing the mode makes it the single source of truth, so the
editor reads back what the teacher chose instead of inferring it.

**Note.** The enum carries `prefix: true`: a bare `none` value would collide with
ActiveRecord's own `none` scope and Rails refuses to define it.

**Status:** settled — covered by model and request specs.

---

## E-3.10 · Percentage and absolute threshold are mutually exclusive

> **Should a rule be prevented from carrying both threshold kinds at once?**

**As built.** `Rule#threshold_matches_mode` rejects a rule carrying both values;
`RulesController#apply_threshold_params` nils out the other column when a mode is
chosen. `Evaluator#points_met?` checks absolute first, then percentage.

**Code.** [`threshold_matches_mode`][c-modecheck] ·
[`apply_threshold_params`][c-applymode] · [the precedence in `points_met?`][c-points]

**Example.** A teacher enters 50 %, saves, then switches the form to "absolute"
and enters 60 points. The controller writes `min_points_absolute = 60` and
`min_percentage = nil`, so no combined state ever reaches the model.

The model validation is the backstop for any other writer — a rake task, a
console session, a future API — where the precedence in `points_met?` would
otherwise silently apply and the percentage would be ignored without a word.

**Why it matters.** Two thresholds in one rule have no defined meaning; the
ordering in `points_met?` would turn that into an arbitrary winner.

**Status:** settled.

---

## Summary

| # | Decision | Status |
|---|---|---|
| E-3.1 | Ungraded ⇒ pending, not failed | settled |
| E-3.2 | A rule must constrain something | settled *(was: untested)* |
| E-3.3 | Manual decisions never auto-overwritten | settled |
| E-3.5 | Multi-lecture policies mean OR | settled |
| E-3.6 | One active rule per lecture (DB index) | settled |
| E-3.7 | One performance policy per campaign (model + index) | settled |
| E-3.8 | Eligibility off only while no data exists | settled |
| E-3.9 | `threshold_mode` is a column | settled *(was: reconstructed)* |
| E-3.10 | Percentage XOR absolute | settled |

**Nothing here still needs a decision.** Every entry has been checked against the
branch and carries a test; what remains is background for the reviewer.

E-3.2 and E-3.9 were open when this page was first written; both have since been
addressed — see the entries for what changed and why.

<!-- ------------------------------------------------------------------ -->
<!-- Code permalinks — all pinned to 877dc84d, the tip of               -->
<!-- muesli-03-eligibility. To re-pin to a later commit, replace the     -->
<!-- SHA in every line below; nothing else in this file refers to it.    -->
<!-- ------------------------------------------------------------------ -->

[c-points]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/evaluator.rb#L49-L57
[c-status]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/evaluator.rb#L59-L71
[c-proposal]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/evaluator.rb#L17-L23
[c-attrs]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/controllers/student_performance/certifications_controller.rb#L302-L320
[c-reeval]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/controllers/student_performance/certifications_controller.rb#L135-L136
[c-confirm]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/controllers/student_performance/certifications_controller.rb#L161-L166
[c-stale]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/certification.rb#L15-L33
[c-certvalid]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/certification.rb#L13
[c-handler]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/registration/policy/student_performance_handler.rb#L25-L34
[c-lectureids]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/registration/policy.rb#L85-L93
[c-ruleindex]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/db/migrate/20260722000003_add_unique_active_rule_per_lecture.rb
[c-singlepolicy]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/registration/policy.rb#L150-L160
[c-policyindex]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/db/migrate/20260722000006_add_unique_student_performance_policy_per_campaign.rb
[c-guard]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/lecture.rb#L1072-L1084
[c-mode]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/rule.rb#L13-L15
[c-applymode]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/controllers/student_performance/rules_controller.rb#L103-L120
[c-modecheck]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/rule.rb#L49-L67
[c-criteria]: https://github.com/MaMpf-HD/mampf/blob/877dc84d5724f3a41d379ab27d9130be341a4c87/app/models/student_performance/rule.rb#L39-L47
