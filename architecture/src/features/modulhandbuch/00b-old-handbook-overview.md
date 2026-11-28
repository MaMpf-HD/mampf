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

## Core Flow

**Once / rarely: base data** (Course tab)
- In the Course tab, Codes (module identity: Kurz, Name, Fachgebiet, Info), Modulhandbücher (one per program + PO, e.g. "Informatik BSc 100%", "… alt") and lookups (Fachgebiet, Course Cycle, Course Source) are created.
- Semesters are created in advance (up to 2030).
- New PO: new Modulhandbuch; the old one gets an Expire Date.

**Every semester**
1. **Copy:** Semester list → `copy to next Semester` on the current semester. Copies **everything** to the next semester: all Module, all Gruppierungen + Zusammenstellung, all Latex Elemente, for every Modulhandbuch (confirmed by staff). Copied Module get Course Source "02 Semester‑Copy".
2. **Update module texts:** one Modul per (Code, Semester), shared by all Modulhandbücher of that semester; every field DE + EN, usually only one filled.
   - Dozent: creates new Module or corrects own ones (Dozent tab) → Course Source "03 / 04 durch Dozent" (?)
   - StudDekanin / Course tab: edit any Modul.
3. **Review and release:** a Modul has a status `created` / `checked` / `published`, set by hand; nothing changes it automatically. **Release (Freigabe) is done by the Studiendekan** (Output_Html: module data "must be released by the Studiendekan" after entry). StudDekan filters by Quelle to see what Dozenten changed. Where exactly the status is set is not visible in the PDFs (?).
4. **Adjust handbooks** (Modulhandbuch tab), per Modulhandbuch + Semester:
   - Gruppierung: names, order, Latex Intro / Extro
   - Zusammenstellung: add / remove Module, set positions
   - Latex Elemente: update Intro (date, Studienverlaufspläne)
5. **Check:** `Check PDF generation of all modules`, then Draft PDF (all Module) → PDF (released only).
6. **Publish:**
   - Output → Latex: generate the handbook LaTeX → PDF
   - Websites read Output html/JSON live (released only; `draft=1` shows unreleased, without login)
   - Git → Export: dump LaTeX records to files for version history



## All possible screens with its variation 
* there is a lot of **duplicate screens**. Most likely: in this framework **access is granted per tab**. So each role gets its own tab with copies of the screens it needs

  | Tab | Info text (translated) | Can do |
  |---|---|---|
  | Course | Module data is maintained. | everything, including lookups and Semester |
  | StudDekanin | Codes are maintained, modules are maintained, modules are released. | Codes, Module, Freigabe, LSF, Semester + copy |
  | Modulhandbuch | Handbooks and groupings are created, modules assigned to groupings, LaTeX elements maintained. | Modulhandbuch, Gruppierung, Zusammenstellung, Latex |
  | Output | Generates data for web and PDF output. | generate LaTeX, docs of the public html/JSON scripts |
  | Dozent | New modules can be created and modules corrected. | correct Module (create / copy also present), pdf |
  | Abfragen | Access to the database via stored SQL queries. | raw SQL (framework feature, planned to drop) |
  | (none) | – | read released data via html/JSON (public) |

  Full texts: [Old system: all screens](20-old-handbook-system-all-screens.md).

  Who uses which tab: see [Roles & Permissions](00c-roles-and-permissions.md).


* There is some variations between these duplicates.

For MaMpf: one screen per thing; roles decide which actions are shown. No duplicate screens to migrate.

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

Roles and who may do what (old tabs, official notes, new roles) are kept in one place: [Roles & Permissions](00c-roles-and-permissions.md).
