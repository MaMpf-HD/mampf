# Parallelization Strategy

This chapter outlines how multiple developers can work on the
Implementation Plan simultaneously. It identifies parallelization
opportunities, conflict hotspots, and coordination strategies for
efficient team collaboration.

```admonish success "High Parallelization Potential"
Steps 3 (FCFS mode) and 5 (Roster maintenance) allow up to 3 developers
to work concurrently on independent PRs.
```

## Overview

The Implementation Plan consists of 14 steps across 4 phases. Some steps
must be sequential due to hard dependencies, while others can be highly
parallelized. With a 3-developer team, strategic work distribution can
significantly reduce total implementation time.


## Step-by-Step Parallelization

### Step 2: Foundations (Sequential)

**Parallelization level:** 1 developer (sequential)

**Sequence:**
1. PR-2.1 (Schema) → PR-2.2 (PolicyEngine) → PR-2.3 (Concerns)

**Why sequential?** Each PR builds directly on the previous. The schema
must exist before the PolicyEngine can reference it; concerns depend on
schema models.

**Optional parallel work:**
- PR-2.4 (Talk as Registerable) can proceed after PR-2.3 if seminars
  are in scope for MVP.

```mermaid
graph LR
    PR21[PR-2.1<br/>Schema] --> PR22[PR-2.2<br/>PolicyEngine]
    PR22 --> PR23[PR-2.3<br/>Concerns]
    PR23 -.->|optional| PR24[PR-2.4<br/>Talk]
    
    style PR21 fill:#ff9999
    style PR22 fill:#ff9999
    style PR23 fill:#ff9999
    style PR24 fill:#ffcc99
```

---

### Step 3: FCFS Mode (High Parallelization)

**Parallelization level:** Up to 3 developers

#### Phase 3a: Admin & Student Foundations

**Parallel tracks (2 developers):**

| Track | PR | Developer Focus |
|-------|-----|----------------|
| A | PR-3.1 | Admin scaffold (campaigns/policies CRUD) |
| B | PR-3.2 | Student index (tabs/filters) |

**Prerequisites:** PR-2.3 must be merged.

**Why parallel?** Both PRs implement different controllers
(`CampaignsController` vs `UserRegistrationsController`) with no shared
code paths.

**Merge order:** Either can merge first; no dependencies between them.

#### Phase 3b: Student FCFS Flows

**Parallel tracks (3 developers):**

| Track | PR | Flow Type |
|-------|-----|-----------|
| A | PR-3.3 | FCFS single-item campaigns |
| B | PR-3.4 | FCFS multi-item picker |
| C | PR-3.5 | FCFS policy-gated registration |

**Prerequisites:** PR-3.1 and PR-3.2 merged.

**Why parallel?** All three implement different branches of
`UserRegistrationsController#show` logic. They share the controller file
but modify different action branches based on campaign configuration.

**Conflict management:**
- Each PR adds distinct routes (`register_single`, `register_multi`, `check_policies`)
- Shared private methods (`ensure_eligible!`, `enforce_capacity!`) can
  be extracted by the first PR to merge
- Last PR to merge handles route file conflicts (rebase before merge)

**Merge strategy:** Flexible order; coordinate in daily standup.

```mermaid
graph TD
    PR23[PR-2.3<br/>Concerns]
    
    subgraph "Phase 3a: Parallel (2 devs)"
        PR31[PR-3.1<br/>Admin scaffold]
        PR32[PR-3.2<br/>Student index]
    end
    
    subgraph "Phase 3b: Parallel (3 devs)"
        PR33[PR-3.3<br/>FCFS single]
        PR34[PR-3.4<br/>FCFS multi]
        PR35[PR-3.5<br/>FCFS policy-gated]
    end
    
    PR36[PR-3.6<br/>Dashboard widget]
    
    PR23 --> PR31
    PR23 --> PR32
    PR31 --> PR33
    PR31 --> PR34
    PR31 --> PR35
    PR32 --> PR33
    PR32 --> PR34
    PR32 --> PR35
    PR33 --> PR36
    PR34 --> PR36
    PR35 --> PR36
    
    style PR31 fill:#99ccff
    style PR32 fill:#99ccff
    style PR33 fill:#90ee90
    style PR34 fill:#90ee90
    style PR35 fill:#90ee90
    style PR36 fill:#ffcc99
```

#### Phase 3c: Dashboard Integration

**Single track:**

| PR | Dependencies |
|----|--------------|
| PR-3.6 | Any student flow PR (3.3, 3.4, or 3.5) merged |

---

### Step 4: Preference-Based (Mixed Parallelization)

**Parallelization level:** 2-3 developers depending on phase

#### Phase 4a: UI & Persistence Foundations

**Parallel tracks (2 developers):**

| Track | PR | Purpose |
|-------|-----|---------|
| A | PR-4.1 | Student preference ranking UI |
| B | PR-4.2 | Roster foundations (models + service) |

**Prerequisites:** Step 3 complete.

**Why parallel?** PR-4.1 uses the stubbed `materialize_allocation!`
interface from PR-2.3. PR-4.2 implements the real roster persistence.
They don't conflict because PR-4.1 only reads the interface.

**Optional parallel work:**
- Developer C can research solver libraries (MCMF vs CP-SAT) and draft
  PR-4.3 structure.

#### Phase 4b: Solver Integration (Sequential Bottleneck)

**Single track (1 developer):**

| PR | Dependencies |
|----|--------------|
| PR-4.3 | PR-4.2 must be merged (needs roster persistence) |

**Why sequential?** The solver's `finalize!` method calls
`materialize_allocation!`, which writes to roster tables created in
PR-4.2. This is a hard dependency.

**Parallel work during PR-4.3:**
- Developer B: Draft views for PR-4.4 (allocation controller UI)
- Developer C: Write integration test suite for allocation flow

#### Phase 4c: Allocation UI & Wiring

**Parallel tracks (2-3 developers):**

| Track | PR | Dependencies |
|-------|-----|--------------|
| A | PR-4.4 | PR-4.3 merged |
| B | PR-4.5 | PR-4.3 merged (can draft in parallel with 4.4) |
| C | PR-4.6 | Independent (dashboard widget) |

**Why parallel?** PR-4.4 adds teacher UI for allocation operations.
PR-4.5 wires student-facing result views. PR-4.6 is an isolated
dashboard widget. Minimal overlap.

**Merge order:** PR-4.4 → PR-4.5 → PR-4.6 (preferred but flexible).

```mermaid
graph TD
    PR36[PR-3.6<br/>Dashboard]
    
    subgraph "Phase 4a: Parallel (2 devs)"
        PR41[PR-4.1<br/>Student prefs UI]
        PR42[PR-4.2<br/>Roster foundations]
    end
    
    subgraph "Phase 4b: Sequential (bottleneck)"
        PR43[PR-4.3<br/>Solver integration]
    end
    
    subgraph "Phase 4c: Parallel (2-3 devs)"
        PR44[PR-4.4<br/>Allocation controller]
        PR45[PR-4.5<br/>Post-allocation wiring]
        PR46[PR-4.6<br/>Dashboard widget]
    end
    
    PR36 --> PR41
    PR36 --> PR42
    PR42 --> PR43
    PR43 --> PR44
    PR43 --> PR45
    PR43 --> PR46
    
    style PR41 fill:#99ccff
    style PR42 fill:#99ccff
    style PR43 fill:#ff9999
    style PR44 fill:#90ee90
    style PR45 fill:#90ee90
    style PR46 fill:#ffcc99
```

---

### Step 5: Roster Maintenance (High Parallelization)

**Parallelization level:** Up to 3 developers

#### Phase 5a: Foundation Work

**Parallel tracks (3 developers):**

| Track | PR | Purpose |
|-------|-----|---------|
| A | PR-5.1 | Read-only roster controller + views |
| B | PR-5.4 | Counters + integrity job |
| C | PR-5.6 | Dashboard widget (manage rosters) |

**Prerequisites:** PR-4.2 merged (roster infrastructure exists).

**Why parallel?** All three read from roster tables but don't modify
them. PR-5.1 displays rosters, PR-5.4 counts participants, PR-5.6 shows
summary stats. No write conflicts.

**Merge order:** Flexible; PR-5.1 should merge first to unblock Phase 5b.

#### Phase 5b: Operations & Permissions

**Parallel tracks (2 developers):**

| Track | PR | Purpose |
|-------|-----|---------|
| A | PR-5.2 | Edit operations (remove/move) |
| B | PR-5.5 | Permissions + tutor read-only variant |

**Prerequisites:** PR-5.1 merged.

**Why parallel?** PR-5.2 adds controller actions for edit operations.
PR-5.5 adds authorization rules (abilities) and conditional UI. Low
conflict risk because they touch different layers.

**Merge order:** Either can merge first.

**Parallel draft work:**
- Developer C: Start PR-5.3 draft (candidates panel) while waiting for
  PR-5.2.

#### Phase 5c: Candidates Panel

**Single track:**

| PR | Dependencies |
|----|--------------|
| PR-5.3 | PR-5.2 merged (needs edit operations to assign candidates) |

```mermaid
graph TD
    PR42[PR-4.2<br/>Roster foundations]
    
    subgraph "Phase 5a: Parallel (3 devs)"
        PR51[PR-5.1<br/>Read-only controller]
        PR54[PR-5.4<br/>Counters + job]
        PR56[PR-5.6<br/>Dashboard widget]
    end
    
    subgraph "Phase 5b: Parallel (2 devs)"
        PR52[PR-5.2<br/>Edit operations]
        PR55[PR-5.5<br/>Permissions]
    end
    
    PR53[PR-5.3<br/>Candidates panel]
    
    PR42 --> PR51
    PR42 --> PR54
    PR42 --> PR56
    PR51 --> PR52
    PR51 --> PR55
    PR52 --> PR53
    
    style PR51 fill:#99ccff
    style PR54 fill:#99ccff
    style PR56 fill:#ffcc99
    style PR52 fill:#90ee90
    style PR55 fill:#90ee90
    style PR53 fill:#90ee90
```

---

## Conflict Hotspots

When multiple developers work in parallel, watch these files for merge
conflicts:

### 1. Routes (`config/routes.rb`)

**Why conflicts occur:** Multiple PRs add new routes to the same
namespace.

**Mitigation strategies:**
- **Designate a "routes owner":** One developer handles all route-related
  conflicts during merge.
- **Use consistent formatting:** Follow Rails conventions for namespace
  blocks and member/collection actions.
- **Rebase frequently:** Pull latest `main` daily before pushing.
- **Coordinate merge order:** Agree in standup which PR merges first.

**Example conflict scenario:**
```ruby
# PR-3.3 adds:
post :register_single

# PR-3.4 adds (same location):
post :register_multi
```

**Resolution:** Both lines coexist; just order them consistently.

---

### 2. Abilities (`app/models/ability.rb`)

**Why conflicts occur:** Multiple PRs add authorization rules to the same
file or concern.

**Mitigation strategies:**
- **Split into concerns:** Create `app/abilities/registration_ability.rb`
  and `app/abilities/roster_ability.rb` to separate workstreams.
- **Use section comments:** Clearly mark sections like `# Registration — FCFS mode`
- **Group related rules:** Keep all rules for one controller together.

**Recommended structure:**
```ruby
# app/models/ability.rb
class Ability
  include CanCan::Ability
  include RegistrationAbility
  include RosterAbility
  include AssessmentAbility
  # ...
end
```

---

### 3. Dashboard Components

**Why conflicts occur:** PRs 3.6, 4.6, 5.6 all add widgets to dashboard
views.

**Mitigation strategies:**
- **Use separate component files:** Each widget is its own component
  (`OpenRegistrationsCard`, `AllocationResultsCard`,
  `ManageRostersCard`).
- **Feature flag each widget:** Enables independent testing without UI
  conflicts.
- **Merge in sequence when possible:** 3.6 → 4.6 → 5.6 minimizes conflicts
  in the main dashboard layout file.

---

### 4. UserRegistrationsController

**Why conflicts occur:** PRs 3.3, 3.4, 3.5 all modify the same controller.

**Mitigation strategies:**
- **Keep actions separate:** Each PR implements distinct actions or
  branches (`if campaign.single_item?` vs `if campaign.requires_preferences?`)
- **Extract shared methods early:** The first PR to merge should extract
  helpers like `ensure_eligible!`, `enforce_capacity!`,
  `build_registration_context`.
- **Coordinate merge order:** Agree which PR merges first; others rebase
  and adopt the extracted methods.

**Example of method extraction:**
```ruby
# First PR to merge extracts:
private

def ensure_eligible!(campaign)
  result = Registration::PolicyEngine.call(campaign, current_user)
  redirect_to(...) unless result.pass?
end
```

Later PRs reuse this method instead of duplicating logic.

---

## Parallelization Summary

**Key insight:** Steps 3 and 5 are highly parallelizable. Step 4 has a
bottleneck at PR-4.3 (solver integration) but allows parallelization
before and after.

```mermaid
graph LR
    subgraph "Legend"
        SEQ[Sequential - Must be done in order]
        PAR2[Parallel - 2 developers can work together]
        PAR3[Parallel - 3 developers can work together]
        BOTTLE[Bottleneck - Blocks other work]
    end
    
    style SEQ fill:#ff9999
    style PAR2 fill:#99ccff
    style PAR3 fill:#90ee90
    style BOTTLE fill:#ff6666
```

```mermaid
flowchart TD
    Start([Start Implementation])
    
    Step2{{"Step 2: Foundations<br/>(Sequential - 1 dev)"}}
    Step3{{"Step 3: FCFS Mode<br/>(Parallel - up to 3 devs)"}}
    Step4{{"Step 4: Preference-Based<br/>(Mixed - 2-3 devs)"}}
    Step4b{{"PR-4.3: Solver<br/>(Bottleneck)"}}
    Step5{{"Step 5: Roster Maintenance<br/>(Parallel - up to 3 devs)"}}
    Done([Implementation Complete])
    
    Start --> Step2
    Step2 --> Step3
    Step3 -->|High parallelization| Step4
    Step4 -->|Phase 4a-4b| Step4b
    Step4b -->|Phase 4c| Step5
    Step5 -->|High parallelization| Done
    
    style Step2 fill:#ff9999
    style Step3 fill:#90ee90
    style Step4 fill:#99ccff
    style Step4b fill:#ff6666
    style Step5 fill:#90ee90
```

