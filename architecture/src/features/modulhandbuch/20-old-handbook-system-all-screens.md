# Current Handbook System

Following this the list of all possible view options in ModuleHandbook at the moment

Some notice:
* `Edit` here is not the only possible action, but it is the only possible action that seems can lead to screen. Other possible action is `Delete` / `Copy` (I do not dare to click Delete so I do not know its behaviour)
* Common pattern on every list: row actions `edit`, `copy`, `delete`; header link `Neu` (new).
* `delete` is replaced by `[n]` when the record is still used by n other records.
* Edit forms: `Reset`, `Speichern`, read-only `tst_create` / `tst_change` (or `Erstellt` / `Geändert`).
  * Most also have a read-only `History` field (Code, Modulhandbuch, Gruppierung, Latex, Semester, LSF, Abfragen).
  * **The Modul edit form (StudDekanin → ModulListe → Edit) has no `History` field**, only `Erstellt` / `Geändert`.
* `Portfolio_Modulhandbuch` is one application of a generic "Portfolio" framework (`portfolio.iwr.uni-heidelberg.de`). The Abfragen help mentions other Portfolio modules (Personen, Buchung, Budget, …). Abfragen and probably Git are framework features, not handbook features.

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

You may notice that there is a lot of **duplicate screens**:
```admonish info "Why so many duplicate screens"
Most likely: in this framework **access is granted per tab**. (Abfragen → Info: "Der User muss Zugriff auf das Modul haben")

So each role gets its own tab with copies of the screens it needs
```



---

## Views

### Course

Module list, master data, lookup tables, and copies of the Modulhandbuch screens. Who used this tab is unknown.

#### Course → Course (Liste)
* Path: main → Course
* List of all Module (per-semester module descriptions).
* Filter: Semester, Fachgebiet, Sprache.
* Columns: Semester, Fachgebiet, Code, Name (EN/DE), PDF, `[n]` = number of Modulhandbücher using it.
  * Name shows two lines (EN and DE) when both are filled, one line otherwise.
* Default filter: **alle Semester** (StudDekan / Dozent lists default to one semester).
* Actions: `edit`, `copy`, `delete` (only if in 0 Modulhandbücher, e.g. IIntS, ILat in WS 2026/27).

Same data as `StudDekanin` → `ModulListe`, over all semesters.

#### Course → Code
* Path: main → Course → Code
* List of all module codes (369). 
* Columns: Kurz, Name, Fachgebiet, Info, tst_change.
  * Info is free text: what the module is, from which semester it is in / out of the MHB, renames, sometimes the lecturer ("Ivan Titov, ab SoSe 2026 im MHB").
  * **Name is the code, not a title.** Kurz and Name are almost always equal; where they differ, Kurz is the sortable form and Name the printed code (`MB01` / `MB1`, `ME09` / `ME9`, `MG01` / `MG1`). The module title only appears in Info.
  * Data quality seen in the list: codes without Fachgebiet (`select ...`: ITA, SCAP, SCMa, SCS, TEST), many placeholder codes without Info (MG01–MG39, MH01–MH31, MC1–4, …), a `TEST` code ("bitte nicht löschen"), codes with spaces (`MA6 IPR`, `MScTI INTROHPC`).
* `edit` opens Code_Edit. `copy` creates a new Code from this one. `delete` only for unused Codes.

#### Course → Code → Edit
* Path: main → Course → Code → edit
* Form: `Name`*, `Kurz`*, `Fachgebiet`, `Info`, `History`.
* Changes one Code. 
* **History** shows old/new value per field change.

#### Course → CourseCycle
* Path: main → Course → CourseCycle
* Lookup list: other, SS, WS, WS/SS (**extended auto**)
* Offering cycle of a module.

#### Course → CourseSource
* Path: main → Course → CourseSource
* Lookup list: 01 Admin, 02 Semester-Copy, 03 erstellt durch Dozent, 04 geändert durch Dozent, 05 Test. (**defined specifically**)
* Tells who created / last changed a Modul. 
* **Used as** filter `Quelle` in StudDekanin → ModulListe.

#### Course → Fachgebiet
* Path: main → Course → Fachgebiet
* Lookup list (DE/EN): Mathematik, Informatik, Allgemeine Module (**defined specifically**)
  * Kurz has a number prefix for the order: `01 Mathematik / 01 Mathematics`, `02 Informatik / 02 Computer Science`, `03 Allgemeine Module / 03 General Modules`.
* Assigned to Code and Modul

#### Course → Semester
* Path: main → Course → Semester
* List of semesters (2013 SoSe … 2030 SoSe): `Kurz, Name, Start, Ende`.
  * Naming: Kurz `2026/27 WiSe`, Name `Wintersemester 2026/27`; Output_Html uses yet another form (`2014ws`).
  * Modules per semester: 117–216 (2013/14 – 2016/17), ~140–177 since 2017.
* **Row action** **`copy to next Semester`** on semesters that have modules (`[n]` = number of modules).
* Semesters without modules can be deleted.
* **Same screen as StudDekanin → SemesterList**.

#### Course → ModulhandbuchListe (→ Edit)
* Path: main → Course → ModulhandbuchListe
* **Same as Modulhandbuch → ModulhandbuchListe**, but **without the `Default Sprache` field**.

#### Course → ModulhandbuchGruppierungListe (→ Edit)
* Path: main → Course → ModulhandbuchGruppierungListe
* **Same as Modulhandbuch → ModulhandbuchGruppierungListe**. 
  * Edit form shows **fewer fields**: no `Vorsemester Gruppierung`, `Überschrift in Tex als`, `Latex Intro`, `Latex Extro`.

#### Course → ModulhandbuchZusammenstellungListe
* Path: main → Course → ModulhandbuchZusammenstellungListe
* **Same as Modulhandbuch → ModulhandbuchZusammenstellungListe**, but modules are **sorted** alphabetically, **without position** numbers.

---

### Modulhandbuch

```admonish info "Intro text"
Create Modulhandbücher, create Gruppierungen, assign Module to Gruppierungen, maintain LaTeX elements.
```

The per-semester screens (Gruppierung, Zusammenstellung, Latex) have a header selector:
`Modulhandbuch: <select> → Semester: <select> → Source: anzeigen / nicht anzeigen`

#### Modulhandbuch → ModulhandbuchListe
* Path: main → Modulhandbuch → ModulhandbuchListe
* List of the 16 Modulhandbücher (one per study program + PO version, e.g. "Informatik BSc 100%", "Informatik BSc 100% alt").
* Columns: Kurz, Name, L (DE/EN), Info, Expire, `[n]` (usage count, so no delete; meaning not visible, probably Gruppierungen over all semesters).
* **Not tied to a semester**.
* `Expire` = `2099-01-01` means "no end"; old POs have real dates (2024-01-01 … 2026-01-01).
* Info holds the PO date ("nach der neuen PO vom 05.10.2022, gültig ab WiSe 2021/22").

#### Modulhandbuch → ModulhandbuchListe → Edit
* Form: `Name`*, `Kurz`*, `Expire Date`, `Default Sprache`, `Info`, `History`.
  * `Expire Date` = until when the Modulhandbuch is active (old POs expire, new ones are 2099).

#### Modulhandbuch → ModulhandbuchGruppierungListe
* Path: main → Modulhandbuch → ModulhandbuchGruppierungListe
* Select Modulhandbuch + Semester → list of its Gruppierungen (sections), sorted by `Kurz` ("01 …", "02 …").
  * The number prefix in `Kurz` **is** the order, with gaps (01, 02, 03, 06, 07 in Informatik BSc 100%).
  * `Info` is used as a note on what the LaTeX intro / extro contains ("… und am Ende der Befehl \newpage").
  * Name EN / Kurz EN are mostly empty, even for German handbooks.
* Columns: Kurz (DE/EN), Name (DE/EN), Info, PDF, `[n]` = modules in the Gruppierung.
* `delete` only for empty Gruppierungen.

#### Modulhandbuch → ModulhandbuchGruppierungListe → Edit
* Form: `Modulhandbuch`*, `Semester`*, `Name DE`*, `Kurz DE`*, `Name EN`, `Kurz EN`,
  * `Vorsemester Gruppierung`* (the same Gruppierung in the previous semester),
  * `Überschrift in Tex als` (e.g. Section), `Latex Intro`, `Latex Extro`, `Info`, `History`.
* Latex Intro / Extro = LaTeX printed before / after the modules of this Gruppierung (e.g. intro text, `\newpage`).

#### Modulhandbuch → ModulhandbuchZusammenstellungListe
* Path: main → Modulhandbuch → ModulhandbuchZusammenstellungListe
* Select Modulhandbuch + Semester → all Gruppierungen with their modules. This is where a handbook is built.
* Per Gruppierung: `ADD: <select module>` adds a module; per module: position number + `Delete`.
  * Gruppierungen are numbered `[1]`, `[2]`, … with their module count `[13]`.
  * Rows show a running number (1, 2, 3, …) **and** an editable position field. Positions have gaps (Wahlmodule Informatik: 1, 2, 5, 6, 8, 12, 15, 20, …): the position is only a sort key.
  * Each module row has a PDF icon (single-module PDF).
* Header: `Informatik BSc 100% - 2026 SoSe - de` (handbook language), icons **Draft PDF** and **PDF**.
* Header action: **`Check PDF generation of all modules`** (test-compiles every module).

#### Modulhandbuch → LatexElementeListe
* Path: main → Modulhandbuch → LatexElementeListe
* Select Modulhandbuch + Semester (+ `Source: anzeigen / nicht anzeigen`, shows the raw LaTeX in the list) → its 3 LaTeX elements:
  - `Header`: LaTeX preamble, packages, ends with `\begin{document}`
  - `Intro`: title page, Präambel, Inhaltsverzeichnis, chapter "Studienverlaufspläne", text up to the first Gruppierung ("Datum muss noch aktualisiert werden!")
  - `Footer`: `\end{document}`

#### Modulhandbuch → LatexElementeListe → Edit
* Form: `Modulhandbuch`*, `Semester`*, `Latex Element`*, `Latex Source` (raw LaTeX), `Info`, `History`.

#### Modulhandbuch → LatexLayoutListe (→ Edit)
* Path: main → Modulhandbuch → LatexLayoutListe
* In the PDFs: identical to LatexElementeListe (same records, same Edit form). (?) separate menu entry for the same data, or a different element type that is empty here.

#### PDF generation of the whole handbook (?)
* Header + Intro + for each Gruppierung (Latex Intro + modules + Latex Extro) + Footer.

---

### StudDekanin (Studiendekan/in)

```admonish info "Intro text"
maintain Codes, maintain Module, release (freigeben) Module.
```


#### StudDekanin → CodeList (→ Edit)
* Path: main → StudDekanin → CodeList
* **Same as Course → Code**, **without the tst_change column**. Same edit form.

#### StudDekanin → ModulListe
* Path: main → StudDekanin → ModulListe
* List of Module of one semester (160 in 2026 SoSe).
* Filter: Semester, Fachgebiet, Sprache, Quelle (CourseSource).
* `Ansicht` (view mode) and `Extra Feld 1–4`: choose extra columns to show in the list.
* Columns: Code, PDF icon.
* Actions: `pdf`, `edit`, `copy`, `delete`, `Neu`.
* `Ansicht` select ("Ansicht Normal"); other views not visible.
* `delete` on **every** row, even modules used in handbooks.
* **Freigabe (release) happens here (?). No release button or field is visible in the PDFs** #TODO: clarify
  * Output_Html says: "Die Modul-Daten müssen nach der Erfassung **vom Studiendekan freigegeben** werden." → **Decided: release is the StudDekan's step.**

#### StudDekanin → ModulListe → Edit
* Path: main → StudDekanin → ModulListe → edit
* Full module form for one Code in one Semester:
  - Head: `Modulbezeichnung (DE)`*, `Modulbezeichnung (EN)`, `Fachgebiet`, `Kürzel / Code`, `Semester`, `Kürzel`
  - DE/EN pairs: `LV-Nr.`, `Leistungspunkte`, `Lehrsprache`, `Lehrende`, `Arbeitsaufwand`, `Dauer`, `Turnus`, `Lehrform / SWS`, `Lernziele`, `Inhalt`, `Voraussetzungen`, `Verwendbarkeit`, `Prüfungsschema`, `Prüfungsmodalitäten`, `Vergabe der LP`, `Literatur`
  - Internal: `Dozent (intern)`, `Bemerkungen`, `Erstellt`, `Geändert`
  - **No status / Freigabe field and no `History` field** in this form.
  - `Kürzel / Code` (select of Codes) and `Kürzel` (free text) are two separate fields; `Dauer` has no "(DE)" label.
  - Example IMS SoSe 2026: almost only the EN fields are filled; created by one person, changed by another.

#### StudDekanin → LSF-SortierungListe (→ Edit)
* Path: main → StudDekanin → LSF-SortierungListe
* List of 21 LSF categories (e.g. "INF Bachelor", "MA Hauptseminare"): Kurz, Name, `[n]` modules.
  * Barely used: 9 categories have modules (1–7 each), 12 are unused (`delete`).
* Edit: `Name`*, `Name Kurz`*, `Info`.
* Modules are assigned to one or more categories (visible only in JSON `lsfsort`). 
* Used to sort modules in LSF.

#### StudDekanin → SemesterList (→ Edit)
Path: main → StudDekanin → SemesterList
Same as Course → Semester, incl. `copy to next Semester`.
Edit: `Name`*, `Name Kurz`*, `Start`*, `Ende`*, `Info`, `History`.

---

### Dozent

Intro text: create new Module and correct Module.

#### Dozent → CourseListe
* Path: main → Dozent → CourseListe
* List of Module of one semester. 
* Filter: Semester, Fachgebiet, Sprache.
* Columns: Semester, Fachgebiet, Code, Name (EN/DE), `[n]` Modulhandbücher.
* Actions: `pdf` (all rows), `edit` (only some rows, others show `-`), `copy`, `Neu`.
  * (?) `edit` only for modules not yet released / created by the Dozent. Otherwise the Dozent uses `copy`.
  * Rows with `edit` in SoSe 2026: IAML, IFML, MD1, MLC1–5, MLDSL, MLIS, MLMT, MLMTP, MLR, MLS1–5, MLSA, MLSMLDS, MM11–MM42, MMA, SCAP … SCS. Several of them are "nicht mehr im MHB" (IAML, IFML, MD1) or in no handbook (MLS1–5 show `delete`). Fits "not released yet" better than "own modules". **Assumption for the new system:** own modules **and** not released (⚑ to verify).
  * `delete` only on rows in 0 handbooks **and** editable (MD1, MLS1–5); IIntS and ME2 are in 0 handbooks but show `-`.

#### Dozent → CourseListe → pdf (PdfExportExample)
* PDF of one module. 
* Layout: title, table with LV-Nr., Name, Kürzel, LP, Dauer, Angebotsturnus, Format, Arbeitsaufwand, Verwendbarkeit, Sprache, Lehrende, Prüfungsschema, then Lernziele, Lerninhalte, Teilnahmevoraussetzungen, Vergabe der LP und Modulendnote, Nützliche Literatur.
* Same layout as one module page in the handbook.

---

### Output

#### Output (Latex)
* Path: main → Output
* Select Modulhandbuch + Semester → generates the LaTeX of the handbook.
* The page also lists the Zusammenstellung of **all** Modulhandbücher of that semester (with ADD / Delete), so it doubles as an overview.
  * Gruppierungen are numbered across all handbooks (1–18 …), not per handbook.
  * English handbooks show both name lines in English ("Compulsory modules [5] / Compulsory modules").
  * WS 2026/27 lists **MLat** where SoSe 2026 lists **ILat**: a code swap between terms, done by hand.

#### Output_Html (html / JSON)
#TODO: Used by external websites to show the handbook

* Path: main → Output → Html
* Used by external websites to show the handbook
* Documentation page for public PHP scripts under `/OUTPUT/`:
  - `web_display_toc.php`: TOC of a Modulhandbuch with links to modules (HTML fragment to embed)
  - `web_page_display_toc.php`: same as full web page
  - `web_display_course.php`: one module, HTML fragment
  - `web_page_display_course.php`: one module, full page
  - `json_code.php`: all Codes as JSON
  - `json_course.php`: one module, all fields as JSON (incl. `lsfsort`)

* Params: `id_modulhandbuch`, `code`, `semester` (default: newest), `draft=1` (also show unreleased modules), `l=de|en` (EN falls back to DE), `encoding=latin1`.
  * `id_modulhandbuch` values (1–18, with gaps) are database ids, so **external links depend on them** (e.g. `?id_modulhandbuch=13` = Informatik BSc 100%).
  * `json_course.php` fields include ones marked "obsolete after WS2015/16" (`prerequisites_*`, `sugknowledge_*`, `objective_*`) and LSF fields (`lsfsort`, `sws_*`, `leistungspunkte_lsf`, `typ_veranstaltung_lsf`).
  * Text on the page: "Die Modul-Daten müssen nach der Erfassung vom Studiendekan freigegeben werden" (see StudDekanin → ModulListe).


---

### Git

#### Git → Export
* Path: main → Git → Export
* Shows the tree Modulhandbuch → Semester → Gruppierung (with Intro / Extro).
* The tree shows Gruppierungen that no longer exist today (e.g. `05 Wahlmodule Technische Informatik` in 2021/22).
* Button `Files erzeugen`: writes all LaTeX records (16 Modulhandbücher, 265 Semester, 1329 Latex-Daten) to files, which are then committed to Git. = version history / backup of the LaTeX sources.

---

### Abfragen

#### Abfragen → Info
* Help page for the SQL query module: stored SQL queries can be attached to a menu (`Add to Modul`) and granted to users (`Grant Access To`). Results as table with Excel export.
  * Granted queries appear for the user as menu item "Persönliche Abfragen" in that module.
  * Raw SQL with full DB access, incl. changing and deleting data ("nur vertrauenswürdigen und erfahrenen Personen").
  * Column names starting with `%` are exported to Excel as numbers.

#### Abfragen → Liste
* List of stored queries: id, Go, Kurz, Name, Modul, Login, `new`. 
* Empty.


