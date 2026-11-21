# Old system → MaMpf Handbook: analysis

Source: 39 PDFs in `old system/`. Tabs in the old system: Course, Modulhandbuch, Stud. Dekan(in), Dozent, Output, Git, Abfragen. (`*_Code_*` files are screens inside the Course tab.)

Legend: ✅ covered by current plan · ⚠️ partly / differs · ❌ missing

---

## 1. Functionality, fields, actions per screen

### Code (= CurriculumModule)
Screens: `Course → Code` (`Code_Code`, `Code_Code_Edit`), `StudDekanin_CodeList(_Edit)`

- Fields: `Name`, `Kurz`, `Fachgebiet`, `Info`, `History`, `tst_create`, `tst_change`
- Actions: list, edit, copy, delete (delete only if unused), Neu
- Notes:
  - Code has **no DE/EN name**. Names live on the per-semester Modul.
  - `Info` is free text holding lifecycle notes ("ab WS 2020/21 im MHB", "ab SS 2026 nicht mehr im MHB", "Umbenennung von …"). No real active/retired flag.
  - Renames usually create a **new Code** (IOPWR → IOPSC, ISWÖk → ISWEco, IPDPA → IMMD).
  - Program variants use separate Codes (IBa_100 / IBa_50, IPK_alt / IPK_neu).

### Modul / Course (= ModuleEdition)
Screens: `StudDekanin_ModulListe(_Edit)`, `Course`, `Dozent_CourseListe`, `Dozent_CourseListe_PdfExportExample`

- Key: one record per (Code, Semester). Shared by all Modulhandbücher of that semester.
- Fields (each content field exists as **DE + EN** pair):
  - `Modulbezeichnung`, `LV-Nr.`, `Leistungspunkte`, `Lehrsprache`, `Lehrende`, `Arbeitsaufwand`, `Dauer`, `Turnus`, `Lehrform / SWS`, `Lernziele`, `Inhalt`, `Voraussetzungen`, `Verwendbarkeit`, `Prüfungsschema`, `Prüfungsmodalitäten`, `Vergabe der LP`, `Literatur`
  - Single: `Fachgebiet`, `Kürzel / Code`, `Semester`, `Kürzel`, `Dozent (intern)`, `Bemerkungen`, `Erstellt`, `Geändert`
  - Only in JSON (not on edit form): `sws_vorlesung`, `sws_uebung`, `leistungspunkte_lsf`, `typ_veranstaltung_lsf`, `lsfsort`, `cycle_name`, `methods_de/en`. Obsolete after WS2015/16: `prerequisites`, `sugknowledge`, `objective`.
- List filters: Semester, Fachgebiet, Sprache, Quelle; Ansicht; Extra Feld 1–4 (extra columns)
- Actions: pdf (single module PDF), edit, copy, delete (only if in 0 Modulhandbücher), Neu
- Last list column = number of Modulhandbücher using the module.
- Dozent list: `edit` only on some rows, the rest show `-`. Rule unknown (see open questions).

### Modulhandbuch (= StudyProgram, **not** Handbook)
Screens: `*_ModulhandbuchListe(_Edit)`

- Term‑independent. 16 records (Informatik BSc 100%, … alt, Lehramt, MSc DaCS, MSc MLDS, SciComp MSc old, …).
- Fields: `Name`, `Kurz`, `Expire Date`, `Default Sprache` (DE/EN), `Info`, `History`
- Actions: edit, copy, delete (if unused), Neu
- Our `Handbook` = (Modulhandbuch, Semester). Not a stored record in the old system; it is implicit through Gruppierung + Latex Elemente.

### Gruppierung (= Section)
Screens: `*_ModulhandbuchGruppierungListe(_Edit)`

- Per (Modulhandbuch, Semester).
- Fields: `Name DE`, `Kurz DE`, `Name EN`, `Kurz EN`, `Vorsemester Gruppierung`, `Überschrift in Tex als` (e.g. Section), `Latex Intro`, `Latex Extro`, `Info`, `History`
- Order is by `Kurz` prefix ("01 …", "02 …").
- Actions: edit, copy, delete (only if 0 modules), PDF column, Neu

### Zusammenstellung (= SectionEntry)
Screens: `*_ModulhandbuchZusammenstellungListe`, `Output`

- Per Gruppierung: list of modules, `ADD: select`, `Delete`, position number (editable, gaps allowed: 5, 6, 8, 12 …)
- Action on page: **"Check PDF generation of all modules"**
- `Output` page shows Zusammenstellung of **all** Modulhandbücher of one semester on one page.

### Latex Elemente / Latex Layout
Screens: `Modulhandbuch_LatexElementeListe(_Edit)`, `Modulhandbuch_LatexLayoutListe(_Edit)`

- Per (Modulhandbuch, Semester): `Header`, `Intro`, `Footer`, raw LaTeX `Latex Source` + `Info`
- `Intro` holds title page, Präambel, Inhaltsverzeichnis, chapter "Studienverlaufspläne" and text up to the first section. Note in Info: "Das Datum muss noch aktualisiert werden!"
- The Layout screen prints identical to Elemente in the PDFs. Unclear if it is a separate thing.

### Semester (= Term)
Screens: `Code_Semester`, `StudDekanin_SemesterList(_Edit)`

- Fields: `Name`, `Name Kurz`, `Start`, `Ende`, `Info`, `History`
- Action: **"copy to next Semester"** = semester‑wide copy (all modules; probably also Gruppierung + Latex Elemente, since those have identical create timestamps). Copied records get Course Source "02 Semester-Copy".
- Future semesters up to 2030 already exist.

### Lookup tables
- `Fachgebiet`: Mathematik / Informatik / Allgemeine Module (DE+EN). Used on Code and Modul, as a filter.
- `Course Cycle`: other, SS, WS, WS/SS.
- `Course Source`: 01 Admin, 02 Semester-Copy, 03 erstellt durch Dozent, 04 geändert durch Dozent, 05 Test. Used as filter `Quelle`.
- `LSF-Sortierung`: 21 categories (INF Bachelor, MA Hauptseminare, SCICOMP Vorlesungen …). A module can be in several (`lsfsort` array). Used for LSF.

### Output
- `Output - Latex`: choose Modulhandbuch + Semester → LaTeX.
- `Output - html / JSON` (public PHP endpoints, used by external websites):
  - `web_display_toc.php`, `web_page_display_toc.php` (TOC, embed / full page)
  - `web_display_course.php`, `web_page_display_course.php` (one module)
  - `json_code.php` (all Codes), `json_course.php` (one module, all fields)
  - Params: `id_modulhandbuch`, `code`, `semester` (default = newest), `draft=1` (include unreleased), `l=de|en` (EN falls back to DE), `encoding=latin1`

### Git Export
- Dumps LaTeX records to files for Git: Modulhandbücher [16], Semester [265], Latex-Daten [1329]. Button "Files erzeugen". = version history of the output.

### Abfragen
- Stored SQL queries: `Name`, `Kurz`, `SQL`, `Add to Modul`, `Grant Access To`, `Info`, History. Run, Excel export. Currently empty list.

### Cross‑cutting
- Field‑level `History` (old/new value, user_id, timestamp) + `tst_create` / `tst_change` on every record.
- `copy` on every list.
- `delete` hidden when record is referenced (`[n]` shown instead).

---

## 2. Gap analysis

| Topic | Old system | Current plan | |
|---|---|---|---|
| CurriculumModule | `Name`, `Kurz`, `Fachgebiet`, `Info`; no DE/EN name | `code`, `name_de`, `name_en` | ⚠️ names are per semester in old |
| Fachgebiet | lookup on Code + Modul | — | ❌ |
| Module retired/active | free text in `Info` | — | ❌ (at least a note field) |
| ModuleEdition content | 17 fields × DE/EN | `language`, `ects`, "description columns" | ⚠️ field list must be defined |
| Language | all fields bilingual; Modulhandbuch has `Default Sprache`; output `l=en` with DE fallback | one `language` per edition, name follows it | ⚠️ **model differs** |
| Lehrsprache | free text ("German or English") | enum `de/en` | ⚠️ |
| One edition per (module, term) | yes | yes | ✅ (old system confirms; variants use separate Codes → answers TODO in 03) |
| Status / Freigabe | released vs. not (`draft` param); probably via `Course Source` | created / checked / published | ⚠️ 2 states + provenance vs 3 states |
| Course Source (provenance) | 01–05 | `cloned_from_id` only | ⚠️ |
| StudyProgram | `Name`, `Kurz`, `Expire Date`, `Default Sprache`, `Info` | `name`, `degree`, `share` enums | ⚠️ enums don't fit (Lehramt, "alt PO", DaCS, MLDS); expire + language missing |
| Multi-program handbook | not used; each variant own Modulhandbuch | open question | ✅ not needed |
| Section | + `Kurz DE/EN`, `Latex Intro`, `Latex Extro`, `Überschrift in Tex als`, `Vorsemester Gruppierung` | `title_de`, `title_en`, `position` | ❌ intro/extro, heading level |
| Section lineage | `Vorsemester Gruppierung` | via clone id map | ✅ (store `cloned_from_id` on Section too) |
| SectionEntry | position, add, delete | position, add, delete, move | ✅ |
| Handbook front matter | `Header` / `Intro` / `Footer` raw LaTeX per (Modulhandbuch, Semester) | one template file | ❌ title page, Studienverlaufspläne, preamble per handbook |
| Content format | LaTeX (intro uses `\pageref`, `\newpage`) | Markdown + pandoc | ⚠️ migration of existing LaTeX |
| Cloning | semester‑wide "copy to next Semester" | per‑handbook CloneService | ⚠️ need "clone all handbooks of a term" |
| Single module PDF | yes (`pdf` per row) | — | ❌ |
| "Check PDF generation of all modules" | yes | — | ❌ |
| Export filter | released only / `draft=1` all | TODO | ✅ answers TODO in 06: `published` / `all` |
| HTML / JSON public endpoints | 6 scripts, used by websites | future extension | ⚠️ **live dependency**, not "future" |
| LSF-Sortierung + LSF fields | yes | — | ❌ (ask if still used) |
| Course Cycle | lookup | — | ❌ (or merge into `Turnus`) |
| Term start/end | `Start`, `Ende` | MaMpf `Term` | ✅ check MaMpf Term has what's needed |
| Audit / History | field‑level on all records | — | ❌ |
| Git export / snapshots | yes | Export Snapshots (future) | ⚠️ |
| Abfragen (SQL) | yes, empty | — | drop; replace with CSV export of lists |
| List filters | Semester, Fachgebiet, Sprache, Quelle, Extra Feld 1–4 | — | ❌ define in UI |
| Delete guard | everywhere | `restrict_with_error` | ✅ |
| copy action | everywhere | EditionCopier, CloneService | ⚠️ no plain "duplicate" for module/section |

---

## 3. Role mapping

| Old menu / role | Does | New role |
|---|---|---|
| Course (Admin) | lookups, Codes, Semester, Modulhandbuch, Gruppierung | admin |
| Stud. Dekan(in) | Codes, Module, Freigabe, LSF-Sortierung, Semester + copy | admin |
| Modulhandbuch | Modulhandbücher, Gruppierung, Zusammenstellung, Latex Elemente | admin |
| Output - Latex, Git | generate LaTeX, Git dump | admin (export: viewer too) |
| Abfragen | raw SQL | — drop |
| Dozent | create new modules, correct modules, single PDF | **no match** → admin for now; Lecturer role (future) |
| Public (html/JSON, `draft=0`) | read released data, no login | **no match** → unauthenticated read‑only endpoint, published only |
| — | read + export | viewer |

---

## 4. Open questions

1. How is a module "freigegeben"? No status field on the edit form. Is it `Course Source = 01 Admin`?
2. Dozent list: why is `edit` only on some rows (IAML, IFML, MD1, MLC*, MM*, SC*)? Released vs. not, or own records?
3. Do lecturers actively use the Dozent menu today? If yes, Lecturer role is not "future".
4. Which websites call the html/JSON scripts? Must URLs/ids stay stable?
5. Is LSF-Sortierung / LSF fields still used?
6. Latex Layout vs. Latex Elemente: same thing?
7. Language: keep bilingual fields (old way) or one language per edition (plan)? Many modules have only EN filled.
8. Existing content is LaTeX: convert to Markdown on import, or keep LaTeX?
9. Is field‑level History needed, or is created/updated by + export snapshots enough?