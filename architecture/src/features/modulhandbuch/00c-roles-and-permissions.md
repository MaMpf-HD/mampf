# Roles & Permissions


## Old system: role → tasks

**Course (admin)**
- Codes: create, edit, copy, delete (only unused)
- Lookups: Fachgebiet, Course Cycle, Course Source
- Semester: create, edit, **copy to next Semester**
- Modulhandbuch: create, edit (without Default Sprache)
- Gruppierung: create, edit (reduced form: no Latex Intro/Extro, no Vorsemester), PDF per Gruppierung
- Zusammenstellung: add / remove modules (no positions)
- Module: list over **all semesters**, edit, copy, delete (only unused), PDF

**Modulhandbuch (handbook editor)**
- Modulhandbuch: create, edit (with Default Sprache)
- Gruppierung: full form (Latex Intro/Extro, heading level, Vorsemester)
- Zusammenstellung: add / remove, **set positions**
- Latex Elemente: Header / Intro / Footer
- **Draft PDF / PDF** of the whole handbook, **Check PDF generation of all modules**

**StudDekan (Studiendekan/in, in practice the coordinator)**
- Codes: create, edit, copy, delete (only unused)
- Module: list per semester with **Quelle** and **Extra Feld** filters, edit, copy, **delete even when used**, PDF
- **Freigabe** (per the Info page; the button isn't visible in the PDFs)
- LSF-Sortierung
- Semester: incl. copy to next Semester

**Dozent (lecturer)**
- Module: list per semester, **create new**, edit (**only some rows**, probably own or unreleased), copy, delete (only unused), PDF
- No Codes, no handbooks, no Freigabe

**Public (no login)**
- HTML/JSON of released modules and handbook TOCs.
- ⚠ `draft=1` is just a URL parameter, so **anyone can see unreleased drafts**. In the new system that must require login.




Screens that I have no idea who have what access rigth

**Output / Git / Abfragen**
- Generate LaTeX, Git dump, raw SQL. Who has access is unknown.


## New system: role → tasks

| Task | admin | approver (optional) | lecturer (later) | viewer | public |
|---|---|---|---|---|---|
| Base data (`StudyProgram`, `CurriculumModule`) | ✓ | | | read | |
| Prepare a term / clone | ✓ | | | | |
| `Handbook`: create, front matter, sections, entries | ✓ | | | read | |
| `ModuleEdition`: create (via handbook) | ✓ | | ✗ (old Dozent could) | | |
| `ModuleEdition`: edit text | ✓ | | own only | | |
| `ModuleEdition`: set status (created / checked / published) | ✓ | ✓ | | | |
| Publish / unpublish `Handbook` | ✓ | ✓ | | | |
| Delete (`ModuleEdition` not in use, empty structure) | ✓ | | | | |
| Draft PDF, single-module PDF, check render | ✓ | ✓ | own only | ✓ | |
| Official PDF | ✓ | ✓ | ✓ | ✓ | ✓ |
| Public handbook / module pages | ✓ | ✓ | ✓ | ✓ | published only |
| History | ✓ | ✓ | own only | | |

## How the old roles map

- **Course + Modulhandbuch + StudDekan → admin.** It's one person in practice, and the tab split was only there because the framework grants access per tab.
- **StudDekan's Freigabe → approver**, but only if the faculty wants Freigabe separated (mail question 2). Otherwise it's part of admin.
- **Dozent → lecturer (later).** One difference: the old Dozent could **create new modules**. In the new system a `ModuleEdition` is only created via a handbook (the "one rule"), so the lecturer only edits. Is that OK, or must a lecturer be able to propose a new module?
- **Public → public**, but without the draft hole.
- **viewer** is new: logged-in read access with drafts (Prüfungsamt, Studienberatung). The old system had nothing like it.
- **StudDekan's "delete even when used"** is not carried over. In the new system, nobody deletes a `ModuleEdition` that a `Handbook` still uses; you remove the entry first.

**Questions this leaves:**
1. Should viewers see drafts, or only official?
2. Approver: wait for the mail.
