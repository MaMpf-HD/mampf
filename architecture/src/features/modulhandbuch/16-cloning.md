# Flows & Screens: Cloning

Copy handbooks into another term. Who may do it: see [Roles & Permissions](00c-roles-and-permissions.md).

---

## Flows

**C1. Prepare a term** (normal case: everything)
1. Handbooks list → **Prepare a term…**
2. Pick target term (e.g., WS 2026/27). Source preselected: latest term with handbooks (SoSe 2026).
3. Summary: "Clone 12 programs from SoSe 2026 → WS 2026/27". Program list collapsed, all active programs ticked.
4. **Prepare** → progress per program.
5. Result (S3): created / reused / skipped / failed per program.
6. **Review changes** → Descriptions list "WS 2026/27 · status created".

**C2. Prepare a term, some programs only**
- Same as C1; step 3 → **Show programs** → untick some.
- Programs that already have a handbook in the target term are listed greyed: "exists".

**C3. Clone one handbook**
1. Handbooks list → row ⋯ → **Clone to another term**.
2. Pick target term → **Clone** → result for that program → opens the new handbook.

**C4. New handbook by cloning**
- New handbook → program + term → **Clone from** → pick the source (any earlier handbook of that program, or of another program for a new PO, see [Base Data](11-base-data.md) P4).

**C5. Target term missing**
- Term picker shows only existing MaMpf terms. Hint: "Term not listed? Create it in term management." (link)

**C6. Already prepared**
- Prepare a term again → all programs show "exists" → nothing to do.

**C7. After cloning**
1. Front matter of each new handbook: `issue_date` empty → set before publishing.
2. Update what changed per term (add / remove modules, edit descriptions).

---

## Screens

### S1. Prepare a term (default)

```
Prepare a term

Target term   [WS 2026/27 ▾]
Source term   [SoSe 2026 ▾]   (latest term with handbooks)

Clone 12 programs from SoSe 2026 → WS 2026/27.
Module descriptions that already exist in WS 2026/27 are reused, others copied.
▸ Show programs (12 selected)
                                            [Cancel] [Prepare]
```

### S2. Prepare a term (programs expanded)

```
▾ Programs (11 of 12 selected)                         [Select all] [None]
  [✓] Informatik BSc 100%                    SoSe 2026 · 39 modules
  [✓] Informatik BSc 50%                     SoSe 2026 · 21 modules
  [ ] Informatik MSc DaCS                    SoSe 2026 · 47 modules
  [—] Mathematik BSc 100%                    exists in WS 2026/27
  Not offered: Informatik BSc 100% alt (expired 2026-01-01)
```

### S3. Result

```
Prepared WS 2026/27
Program                   Result
Informatik BSc 100%       39 created
Informatik BSc 50%         4 created · 17 reused
Mathematik BSc 100%       exists (skipped)
Informatik MSc DaCS       45 created · 2 reused · 1 skipped (inactive: IAML)
SciComp MSc               ✕ failed: <reason>                       [Retry]

[Go to handbooks WS 2026/27]   [Review descriptions (created)]
```

### S4. Clone one handbook

```
Clone Informatik BSc 100% · SoSe 2026
Target term [WS 2026/27 ▾]
⚠ A handbook for WS 2026/27 exists already.        (shown instead of the button)
                                            [Cancel] [Clone]
```

---

## Small Decisions

1. Default = everything, programs collapsed (staff: "select semester, all cloned").
2. Source term selectable, so a skipped term can be bridged (e.g., clone WS 2025/26 → WS 2026/27).
3. One failed program does not stop the others; **Retry** per program.
