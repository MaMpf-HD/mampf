# Roles & Permissions

```admonish info "Single source for roles"
This is the **only** place where roles are named. Flow and screen docs describe actions ("release", "edit text", …) and link here; they do not say who may do them.
```

## How the roles are derived

We do not know the people behind the old system. We only know its **tabs**, and the old framework grants access **per tab** (Abfragen → Info: "Der User muss Zugriff auf das Modul haben"). So:

- **One role per old tab** whose purpose is documented by the tab's own Info page.
- **Certainty:**
  - **sure**: the action exists in the StudDekanin, Dozent or Modulhandbuch tab, or an official note says so.
  - **assumed** ⚑: our guess; listed in [To Verify](pending-thing-need-to-verify.md).
- The **Course** tab gets no role of its own: every action in it also exists in the StudDekanin or Modulhandbuch tab, except the lookup tables, which are dropped. Who used the Course tab is unknown ⚑.

### Official notes in the old system

| Source | Text (original) | Meaning |
|---|---|---|
| StudDekanin → Info | "Im Modul [St. Dekan(in)] werden die Codes gepflegt, werden die Module gepflegt, werden die Module freigegeben" | Codes and Module are maintained, Module are **released** here |
| Dozent → Info | "Im Dozent-Modul können neue Module angelegt und Module korrigiert werden." | Lecturers **create** new Module and **correct** Module |
| Modulhandbuch → Info | "werden die Modulhandbücher angelegt, werden die Gruppierungen der Modulhandbücher angelegt, werden die Modulen den Gruppierungen … zugeordnet, werden die Latex Elemente … erfasst und gepflegt" | Handbooks, sections, module assignment and LaTeX are done here |
| Output → Html | "Die Modul-Daten müssen nach der Erfassung vom Studiendekan freigegeben werden." | Release is the **Studiendekan's** step |
| Abfragen → Info | "Der User muss Zugriff auf das Modul haben" | Access is granted **per tab** |

### Roles

| Role | From old tab | Who (as far as known) |
|---|---|---|
| `studdekan` | StudDekanin | Studiendekan/in (in practice maybe a coordinator ⚑) |
| `dozent` | Dozent | Lecturers |
| `handbook_editor` | Modulhandbuch | Unknown ⚑ |
| `viewer` | none (new) ⚑ | Logged‑in readers, e.g. Prüfungsamt, Studienberatung |
| public | Output → Html (scripts) | Anyone, no login |

One person can have several roles (e.g., `studdekan` + `handbook_editor`).

---

## Actions → roles

| Action (new system) | Old tab(s) with this action | Official note | Role | Certainty |
|---|---|---|---|---|
| Create / edit `CurriculumModule` (old Code) | Course, StudDekanin | StudDekanin Info: "Codes gepflegt" | `studdekan` | sure |
| Create / edit / expire `StudyProgram` (old Modulhandbuch) | Course, Modulhandbuch | Modulhandbuch Info: "Modulhandbücher angelegt" | `handbook_editor` | sure |
| Create `Term` (old Semester) | Course, StudDekanin | – | MaMpf, outside the handbook | ⚑ who creates terms in MaMpf |
| Prepare a term / clone (old "copy to next Semester") | Course, StudDekanin | – | `studdekan` | sure |
| `Handbook`: create, front matter (old Latex Elemente) | Modulhandbuch | Modulhandbuch Info: "Latex Elemente erfasst und gepflegt" | `handbook_editor` | sure |
| `Section`s (old Gruppierung) | Course (reduced form), Modulhandbuch | Modulhandbuch Info: "Gruppierungen angelegt" | `handbook_editor` | sure |
| `SectionEntry`: add / remove / order modules (old Zusammenstellung) | Course, Modulhandbuch, Output | Modulhandbuch Info: "Modulen den Gruppierungen zugeordnet" | `handbook_editor` | sure |
| Draft PDF, official PDF, check render of a handbook | Modulhandbuch (Course: PDF only) | – | `handbook_editor` | sure |
| Download LaTeX (old Output → Latex) | Output | – | `handbook_editor` | ⚑ who used the Output tab |
| Publish / unpublish a `Handbook` | none (new) | – | `handbook_editor` | ⚑ assumed |
| Create a `ModuleEdition` (old Modul `Neu`) | Course, StudDekanin, Dozent | Dozent Info: "neue Module angelegt" | `studdekan`, `dozent`; `handbook_editor` via "add module" (find‑or‑create) | sure / ⚑ for `handbook_editor` |
| Edit `ModuleEdition` text | Course, StudDekanin, Dozent | StudDekanin Info: "Module gepflegt"; Dozent Info: "Module korrigiert" | `studdekan` (all); `dozent` (own + not released ⚑) | sure / ⚑ restriction |
| Set status `created` / `checked` | none visible | – | `studdekan`; `dozent` (own + not released) | ⚑ assumed |
| Set / remove `published` (Freigabe) | StudDekanin | StudDekanin Info: "Module freigegeben"; Output Html: "vom Studiendekan freigegeben" | `studdekan` only | sure |
| Delete a `ModuleEdition` (only when in no handbook) | Course (unused), StudDekanin (any), Dozent (some rows) | – | `studdekan`; `dozent` ⚑ | sure / ⚑ |
| Descriptions list with source filter (old Quelle) | StudDekanin | – | `studdekan` | sure |
| Single module PDF | Course, StudDekanin, Dozent, Modulhandbuch | – | all logged‑in roles | sure |
| Read everything (incl. drafts?) | none (new) | – | `viewer` | ⚑ drafts or published only? |
| See history of a record | edit forms of all tabs | – | anyone who can edit the record | ⚑ assumed |
| Public handbook / module pages | Output → Html | – | public (published only) | sure |

Dropped (no role needed): lookup tables Fachgebiet / Course Cycle / Course Source (Course tab), LSF‑Sortierung (StudDekanin), Git Export, Abfragen.

```admonish warning "⚑ Assumption: dozent edits own, unreleased descriptions only"
In the old Dozent list, `edit` appears only on some rows (SoSe 2026: IAML, IFML, MD1, MLC*, MLS*, MM*, SC* …); these look like modules **not released yet**. It also makes sense that a lecturer edits **only their own** modules (`responsible_user_id`). We assume both: a `dozent` can edit a description only if it is theirs **and** not `published`. **TODO: verify.**
```

```admonish note "Changes against the old system"
- **No "delete even when used".** The old StudDekanin list could delete any Modul. In the new system nobody deletes a `ModuleEdition` that a `Handbook` still uses; the entry is removed first.
- **No draft hole.** Old `draft=1` showed unreleased modules to anyone. Drafts now need a login and a role.
- **Scope:** the overview lists Dozent self‑editing as "out (for now)". The `dozent` rows above describe the target; whether they are in the first version is a scope decision.
```

---

## Old system: tab → actions

**Course** (owner unknown ⚑)
- Codes: create, edit, copy, delete (only unused)
- Lookups: Fachgebiet, Course Cycle, Course Source
- Semester: create, edit, **copy to next Semester**
- Modulhandbuch: create, edit (without Default Sprache)
- Gruppierung: create, edit (reduced form: no Latex Intro/Extro, no Vorsemester), PDF per Gruppierung
- Zusammenstellung: add / remove modules (no positions)
- Module: list over **all semesters**, edit, copy, delete (only unused), PDF
- Widest view, but its copies lack the newer features (Default Sprache, Latex Intro/Extro, positions, Draft PDF): more an overview than a working tab.

**Modulhandbuch**
- Modulhandbuch: create, edit (with Default Sprache)
- Gruppierung: full form (Latex Intro/Extro, heading level, Vorsemester)
- Zusammenstellung: add / remove, **set positions**
- Latex Elemente: Header / Intro / Footer
- **Draft PDF / PDF** of the whole handbook, **Check PDF generation of all modules**

**StudDekanin**
- Codes: create, edit, copy, delete (only unused)
- Module: list per semester with **Quelle** and **Extra Feld** filters, edit, copy, **delete even when used**, PDF
- **Freigabe** (per the Info page; the button isn't visible in the PDFs)
- LSF‑Sortierung
- Semester: incl. copy to next Semester

**Dozent**
- Module: list per semester, **create new**, edit (**only some rows**), copy, delete (only unused), PDF
- No Codes, no handbooks, no Freigabe

**Output / Git / Abfragen** (owner unknown ⚑)
- Generate LaTeX, Git dump, raw SQL.
- The Output tab can also add / remove modules from handbooks (probably a leftover from copying the screen).

**Public (no login)**
- HTML/JSON of released modules and handbook TOCs; `draft=1` shows unreleased ones to anyone.

---

## Open questions

1. Who used the Course, Output, Git and Abfragen tabs?
2. Who is `handbook_editor` in practice? Same person as the Studiendekan?
3. Should `viewer` see drafts, or only published content?
4. `dozent`: own + not released only (see assumption above)? May a lecturer still create a new module?
5. Who creates `Term`s in MaMpf?
