## Basic flows

Notice that this flow is just deduction assumption

### 1. Prepare a new semester
1. StudDekanin → SemesterList: semester exists already (created up to 2030).
2. On the current semester: `copy to next Semester`.
   → copies all Module (CourseSource = 02 Semester-Copy), and (?) Gruppierungen, Zusammenstellung, Latex Elemente of all Modulhandbücher.
   → each new Gruppierung links to its `Vorsemester Gruppierung`.

### 2. Maintain modules
1. New module: Course → Code → `Neu` (Kurz, Name, Fachgebiet, Info).
2. Module text for a semester:
   - Dozent → CourseListe → `Neu` / `edit` / `copy`, or
   - StudDekanin → ModulListe → `Neu` / `edit` / `copy`.
3. Check: `pdf` on the row.
4. Retire a module: write "ab … nicht mehr im MHB" in Code `Info` and remove it from the Zusammenstellung. Codes are not deleted.
5. Rename: usually a new Code + note in `Info` of both Codes.

### 3. Release (Freigabe)
1. StudDekanin reviews Module (filter `Quelle` = Dozent).
2. StudDekanin releases (?). Unreleased modules are hidden in Output html/JSON unless `draft=1`.

## 4. Build a handbook for a semester
1. Modulhandbuch → ModulhandbuchListe: Modulhandbuch exists (new one only for a new PO / program).
2. Modulhandbuch → GruppierungListe: select Modulhandbuch + Semester; add / edit Gruppierungen (name, order via Kurz, Latex Intro / Extro).
3. Modulhandbuch → ZusammenstellungListe: per Gruppierung `ADD` modules, set positions, `Delete` modules no longer offered.
4. `Check PDF generation of all modules`.
5. Modulhandbuch → LatexElementeListe: update Header / Intro / Footer (date, Studienverlaufspläne).

### 5. Publish
1. Output → Latex: select Modulhandbuch + Semester → LaTeX → PDF (compiled outside? (?)).
2. Websites read Output html/JSON live (released data, newest semester by default).
3. Git → Export → `Files erzeugen` → commit to Git.

### 6. Lookups (rare)
Course → Fachgebiet / CourseCycle / CourseSource, StudDekanin → LSF-SortierungListe: add or edit entries.