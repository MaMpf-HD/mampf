# Roles & Permissions

```admonish info "Single source for roles"
This is the **only** place where roles are named. Flow and screen docs describe actions ("release", "edit text", …) and link here; they do not say who may do them.
```

## One role, one assignment

Access is decided by **two different checks**:

| Check | How | Old tab(s) | Who |
|---|---|---|---|
| **Role** `dean_of_studies` | user has the role (granted by an admin) | StudDekanin, Course, Modulhandbuch, Output | Studiendekan/in (Dean of Studies) and the staff working for them |
| **Assignment** (no role) | `module_edition.responsible_user_id == current_user.id` | Dozent | Any logged‑in user assigned to a description, usually its lecturer |
| Public (no check) | no login | Output → Html (scripts) | Anyone; published content only |

- **`dean_of_studies`** is the only role in the handbook. It runs everything: base data, module descriptions, handbooks, release, term preparation, export.
- **"Lecturer" is not a role.** Nobody grants it and nothing stores it. It is just the word for "the user assigned to this description". The check is a user id match on one `ModuleEdition`, so the same user can be assigned to IAD and not to IPK. An assigned user only **edits the text** of that description: no create, no delete, no release.
- **Scope:** the role is faculty‑wide (one faculty uses the handbook). Limiting it to a subject area or study program later needs a scope table; nothing in the current design blocks that.

```admonish tip "Rule of thumb for flow and screen docs"
Write "the Dean of Studies" for role‑based actions and "the assigned lecturer" for assignment‑based ones. Never write `lecturer` as if it were a role.
```

## Why one role is enough

We do not know the people behind the old system. We only know its **tabs**. The old framework grants access **per tab** (Abfragen → Info: "The user must have access to the module"), which is why the same screens appear in several tabs. The tab Info texts (see [Old system: all screens](20-old-handbook-system-all-screens.md)) give the picture:

| Old tab | Info text (translated) | Read as |
|---|---|---|
| StudDekanin | Codes are maintained, modules are maintained, modules are released. | Dean of Studies |
| Course | Module data is maintained. | Same work as StudDekanin → Dean of Studies |
| Modulhandbuch | Handbooks and their groupings are created, modules are assigned to groupings, LaTeX elements are maintained. | Building the handbook from the Dean's data → Dean of Studies |
| Output | Generates data for web and PDF output. | Final step of the handbook → Dean of Studies |
| Dozent | New modules can be created and modules corrected. | Lecturer |
| Output → Html | "Module data must be released by the Dean of Studies after it has been entered." | Release is the Dean's step |

- **Course, StudDekanin, Modulhandbuch, Output** all serve one job: maintain the central data, assemble the handbook, and release and output it. They are copies of the same screens for the same people, so they become one role.
- **Dozent:** the Dozent list shows module descriptions that already exist in the semester. They are created centrally (by semester copy or by the Dean of Studies) and then **show up** in the lecturer's list. The lecturer corrects them; `edit` appears only on some rows. This is a per‑record right, not a tab‑wide one, so it becomes the **assignment** check, not a role. The old Info text also says "create new modules", but in the new system a new description is created by the Dean of Studies (see [Changes against the old system](#changes-against-the-old-system)).
- **Git, Abfragen:** dropped, so they need no role.
- **Viewer** (read‑only logged‑in user): dropped. Read access to published content is covered by the public pages. Drafts are seen by the Dean of Studies, and by the assigned lecturer for their own descriptions.

One person can hold both roles.

---

## Actions → roles

✓ = allowed, – = not allowed. The last column is the assignment check, not a role.

| Action (new system) | Old tab(s) | Role `dean_of_studies` | Assigned lecturer |
|---|---|---|---|
| Create / edit `CurriculumModule` (old Code) | Course, StudDekanin | ✓ | – |
| Create / edit / expire `StudyProgram` (old Modulhandbuch) | Course, Modulhandbuch | ✓ | – |
| Prepare a term / clone (old "copy to next Semester") | Course, StudDekanin | ✓ | – |
| `Handbook`: create, edit front matter (old Latex Elemente) | Modulhandbuch | ✓ | – |
| `Section`s (old Gruppierung) | Course, Modulhandbuch | ✓ | – |
| `SectionEntry`: add / remove / order modules (old Zusammenstellung) | Course, Modulhandbuch, Output | ✓ | – |
| Create a `ModuleEdition` (old Modul `Neu`, incl. "add module" find‑or‑create) | Course, StudDekanin, Dozent | ✓ | – |
| Assign a lecturer to a `ModuleEdition` (`responsible_user_id`) | none (new) | ✓ | – |
| Edit `ModuleEdition` text | Course, StudDekanin, Dozent | ✓ all | ✓ if not `published` ⚑ |
| Set status `created` / `checked` | none visible | ✓ | – ⚑ |
| Set / remove `published` (Freigabe) | StudDekanin | ✓ | – |
| Delete a `ModuleEdition` (only when in no handbook) | Course, StudDekanin, Dozent | ✓ | – |
| Descriptions list (all terms, all modules, source filter) | Course, StudDekanin | ✓ | "My descriptions" only |
| Draft PDF, official PDF, check render of a handbook | Modulhandbuch | ✓ | – |
| Publish / unpublish a `Handbook` | none (new) | ✓ | – |
| Single module PDF | all tabs | ✓ | ✓ |
| See history of a record | edit forms | ✓ | ✓ |
| Public handbook / module pages (published only) | Output → Html | anyone | anyone |

Outside the handbook:
- Creating a `Term` (old Semester) is done in the host system, not here ⚑.
- Granting the `dean_of_studies` role is done by an admin of the host system. Assigning lecturers is done by the Dean of Studies, per description.

Dropped (no role needed): lookup tables Fachgebiet / Course Cycle / Course Source, LSF‑Sortierung, Git Export, Abfragen.

```admonish warning "⚑ Assumption: assigned lecturer edits only unreleased descriptions"
In the old Dozent list, `edit` appears only on some rows (SoSe 2026: IAML, IFML, MD1, MLC*, MLS*, MM*, SC* …). These look like modules **not released yet**. We assume: a user can edit a description only if it is **assigned to them** (`responsible_user_id`) **and** not `published`. After release, changes go through the Dean of Studies. **TODO: verify** (see [To Verify](pending-thing-need-to-verify.md#1-roles)).
```

## Changes against the old system

- **Lecturers do not create or delete.** The old Dozent tab had `Neu`, `copy` and (on some rows) `delete`. In the new system the Dean of Studies creates every description (or it comes from cloning) and assigns it; the lecturer fills in or corrects the text.
- **No "delete even when used".** The old StudDekanin list could delete any Modul. In the new system a `ModuleEdition` that a `Handbook` still uses cannot be deleted; remove the entry first.
- **No draft hole.** Old `draft=1` showed unreleased modules to anyone. Drafts now need a login: the role, or an assignment.
- **No per‑tab copies.** One screen per thing; the role decides which actions are shown.
- **Scope:** lecturer editing may come after the first version. Until then the Dean of Studies enters the texts.

---

## Old system: tab → actions

**Course** (→ `dean_of_studies`)
- Codes: create, edit, copy, delete (only unused)
- Lookups: Fachgebiet, Course Cycle, Course Source
- Semester: create, edit, **copy to next Semester**
- Modulhandbuch: create, edit (without Default Sprache)
- Gruppierung: create, edit (reduced form: no Latex Intro/Extro, no Vorsemester), PDF per Gruppierung
- Zusammenstellung: add / remove modules (no positions)
- Module: list over **all semesters**, edit, copy, delete (only unused), PDF
- Widest view, but its copies lack the newer features (Default Sprache, Latex Intro/Extro, positions, Draft PDF): more an overview than a working tab.

**Modulhandbuch** (→ `dean_of_studies`)
- Modulhandbuch: create, edit (with Default Sprache)
- Gruppierung: full form (Latex Intro/Extro, heading level, Vorsemester)
- Zusammenstellung: add / remove, **set positions**
- Latex Elemente: Header / Intro / Footer
- **Draft PDF / PDF** of the whole handbook, **Check PDF generation of all modules**

**StudDekanin** (→ `dean_of_studies`)
- Codes: create, edit, copy, delete (only unused)
- Module: list per semester with **Quelle** and **Extra Feld** filters, edit, copy, **delete even when used**, PDF
- **Freigabe** (per the Info page; the button isn't visible in the PDFs)
- LSF‑Sortierung
- Semester: incl. copy to next Semester

**Output** (→ `dean_of_studies`)
- Generate LaTeX of a handbook, docs of the public HTML / JSON scripts.
- Can also add / remove modules from handbooks (probably a leftover from copying the screen).

**Dozent** (→ assignment check, no role)
- Module: list per semester, `Neu`, edit (**only some rows**), copy, delete (only unused), PDF
- No Codes, no handbooks, no Freigabe

**Git / Abfragen** (dropped)
- Git dump of the LaTeX records; raw SQL queries.

**Public (no login)**
- HTML/JSON of released modules and handbook TOCs; `draft=1` shows unreleased ones to anyone.

---

## Open questions

See [To Verify → Roles](pending-thing-need-to-verify.md#1-roles).
