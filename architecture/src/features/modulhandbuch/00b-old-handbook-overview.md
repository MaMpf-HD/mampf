# Current Handbook Overview

Following this the list of all possible view options in ModuleHandbook at the moment

```
Portfolio_Modulhandbuch
├── Course
│   ├── Course (Liste)
│   ├── Code                          → Edit
│   ├── CourseCycle
│   ├── CourseSource
│   ├── Fachgebiet
│   ├── Semester
│   ├── ModulhandbuchListe            → Edit
│   ├── ModulhandbuchGruppierungListe → Edit
│   └── ModulhandbuchZusammenstellungListe
├── Modulhandbuch
│   ├── Intro
│   ├── ModulhandbuchListe            → Edit
│   ├── ModulhandbuchGruppierungListe → Edit
│   ├── ModulhandbuchZusammenstellungListe
│   ├── LatexElementeListe            → Edit
│   └── LatexLayoutListe              → Edit
├── StudDekanin
│   ├── Intro
│   ├── CodeList                      → Edit
│   ├── ModulListe                    → Edit
│   ├── LSF-SortierungListe           → Edit
│   └── SemesterList                  → Edit
├── Dozent
│   ├── Intro
│   └── CourseListe                   → pdf (PdfExportExample)
├── Output
│   ├── Output (Latex)
│   └── Output_Html (html / JSON)
├── Git
│   └── Export
└── Abfragen
    ├── Info
    └── Liste
```


Notice: 
* there is a lot of **duplicate screens**. Most likely: in this framework **access is granted per tab**. So each role gets its own tab with copies of the screens it needs

  | Tab | Who | Can do |
  |---|---|---|
  | Course | system admin | everything, including lookups and Semester |
  | StudDekanin | Studiendekan/in | Codes, Module, Freigabe, LSF, Semester + copy |
  | Modulhandbuch | handbook editor | Modulhandbuch, Gruppierung, Zusammenstellung, Latex |
  | Dozent | lecturer | create and correct Module, pdf |
  | (none) | public / website | read released data via html/JSON |


* There is some variations between these duplicates.

For MaMpf: one screen per thing; roles decide which actions are shown. No duplicate screens to migrate.

## All possible screens with its variation
So final list of all possible screens with its variation:

* **Module list** (Course - Liste / StudDekanin Modul Liste / Dozent Course-Liste)

  | | Course | StudDekanin | Dozent |
  |---|---|---|---|
  | Filter | Semester, Fachgebiet, Sprache | Semester, Fachgebiet, Sprache, **Quelle** | Semester, Fachgebiet, Sprache |
  | Extra | — | **Ansicht, Extra Feld 1–4** | — |
  | Columns | Semester, Fachgebiet, Code, Name, PDF | Code, PDF only | Semester, Fachgebiet, Code, Name, pdf |
  | edit | all rows | all rows | **only some rows** |
  | copy | yes | yes | yes |
  | delete | only if unused, else `[n]` | **on every row**, even used ones | only if unused, else `[n]` |
  | Neu | yes | yes | yes |

  The edit forms for Course and Dozent are not in the PDFs. Only the StudDekanin Modul Edit form is there.

* **Code** (Course Code Liste / StudDekanin Code Liste)
  - Same actions: edit, copy, delete-if-unused, Neu.
  - Same edit form.
  - The only difference is that Course shows a `tst_change` column.

* **Semester** (Course / StudDekanin)
  - Identical, including `copy to next Semester`.

* **Modulhandbuch** (Course / Modulhandbuch)

  | | Course | Modulhandbuch |
  |---|---|---|
  | List column `L` (language) | no | yes |
  | Edit `Default Sprache` | no | yes |

* **Gruppierung** (Course / Modulhandbuch)

  | | Course | Modulhandbuch |
  |---|---|---|
  | Header selector | Modulhandbuch → Semester | Modulhandbuch → Semester → **Source** (anzeigen / nicht anzeigen) |
  | List | same: edit, copy, delete-if-empty, PDF per Gruppierung | same |
  | Edit form | Name/Kurz DE+EN, Info | + **Vorsemester Gruppierung, Überschrift in Tex als, Latex Intro, Latex Extro** |

* **Zusammenstellung** (Course / Modulhandbuch / Output - Latex)

  | | Course | Modulhandbuch | Output - Latex |
  |---|---|---|---|
  | ADD / Delete module | yes | yes | **yes** |
  | Position field (editable) | no, sorted A–Z | **yes** | no |
  | PDF per module | yes | yes | no |
  | Handbook PDF | PDF | **Draft PDF + PDF** | (generate LaTeX) |
  | Language shown in header | no | yes ("- de") | no |
  | Check PDF generation of all modules | no | **yes** | no |

Only in one tab
* **Latex Elemente / Latex Layout** (Modulhandbuch)
* **LSF-Sortierung** (StudDekanin)
* **Course Cycle**, **Course Source**, **Fachgebiet** (Course)
* **Git Export**
* **Abfragen**

---

## Roles 

| Tab | Who | Can do |
|---|---|---|
| Course | system admin | everything, including lookups and Semester |
| StudDekanin | Studiendekan/in | Codes, Module, Freigabe, LSF, Semester + copy |
| Modulhandbuch | handbook editor | Modulhandbuch, Gruppierung, Zusammenstellung, Latex |
| Dozent | lecturer | create and correct Module, pdf |
| (none) | public / website | read released data via html/JSON |

| Role | Job |
|---|---|
| Course (admin) | create master data, look at everything |
| StudDekan | review and release modules, clean up, LSF |
| Modulhandbuch | build handbooks, LaTeX, PDF |
| Dozent | write their own modules |

- **StudDekanin can delete any module, even one in use.** 
  * That's the strongest permission of any role on the module list.
- **Dozent is restricted role, can only take actions on seen rows**
  * hence no filter (as it may not necessary), no lookup support
- **The Output tab can still add and remove modules from a handbook.** That's probably unintended, a leftover from copying the screen over.
- **Course is a superset in information** but **lack of features.** 
  * It can open almost everything, but its copies lack the newer features (Default Sprache, Latex Intro/Extro, positions, Draft PDF).
  * Seems like this is more about seeing overall data, not possible for strong manipulation
  * #TODO: elaborate which can be done by which

- **Course (admin): master data and overview**
  - Creates the base data: Codes, the lookup tables (Fachgebiet, Course Cycle, Course Source), Semester and Modulhandbuch.
  - Has the widest view
  - Records in use are protected: delete only works when nothing uses them.

- **StudDekan: module content, review, cleanup**
  - Works **one semester at a time**, 
  - better filters
    - Quelle filter is exactly what you need to review what Dozenten changed.
  - Stronger delete: 
    - modules can be deleted even while in use.
  - More edit rights: 
    - LSF-Sortierung