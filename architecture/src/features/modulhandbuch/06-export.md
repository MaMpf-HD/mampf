# Export

Export turns a `Handbook` (or one `ModuleEdition`) into something people read: a PDF, or a public web page.

**Example:** Before WS 2026/27, the admin downloads the **Draft PDF** of Informatik BSc 100% to proofread all modules, including unreleased ones. After review, the **Official PDF** contains only published modules, and the institute website shows the same handbook as a page.

| | Old | New |
|---|---|---|
| Whole handbook PDF | Modulhandbuch → Zusammenstellung: **Draft PDF** / **PDF** icons | Handbook editor, Handbooks list: **Draft PDF** / **Official PDF** |
| LaTeX source | Output → Latex (select Modulhandbuch + Semester) | Handbook editor: **Download LaTeX** (admin) |
| Check all modules | Modulhandbuch → Zusammenstellung: **Check PDF generation of all modules** | Handbook editor: **Check all modules render** |
| Single module PDF | `pdf` per row (Course, StudDekanin, Dozent lists) | Descriptions list + edit page, handbook editor row: **PDF** |
| Section PDF | `PDF` per Gruppierung | Dropped (use Draft PDF) |
| Public web / JSON | Output html/JSON (PHP scripts, no login) | Public handbook + module pages, JSON |
| Version history | Git → Export | Export snapshots ([future](10-future-extensions.md)) |

| Action | admin | viewer | lecturer (later) | public |
|---|---|---|---|---|
| Official PDF (published `Handbook`) | ✓ | ✓ | ✓ | ✓ |
| Draft PDF | ✓ | ✓ | | |
| Single module PDF | ✓ | ✓ | own only | published only |
| Download LaTeX, check render | ✓ | | | |
| Public pages / JSON | ✓ (+ draft preview) | ✓ | ✓ | published only |

---

## How the PDF Is Built

### Old: LaTeX pieces glued together

The old system stores **pieces of raw LaTeX** in the database and joins them in order:

```
Latex Element "Header"     → \documentclass…, packages, \begin{document}
Latex Element "Intro"      → title page, \tableofcontents, Präambel,
                             Studienverlaufspläne, \chapter{Pflichtbereich}
for each Gruppierung:
    heading                → \section{Pflichtmodule Informatik}
    Latex Intro            → "Nachfolgend sind die Pflichtmodule …"
    each module            → fixed module page (table: LV-Nr, LP, Dauer, …)
    Latex Extro            → \newpage   (or \chapter{Wahlbereich} …)
Latex Element "Footer"     → \end{document}
```

The staff types LaTeX by hand: `\newpage` for a new page, `\chapter{Wahlbereich}` hidden in an Extro to start a chapter, `\pageref{…}` for "see page 7". **Content and layout are mixed in the same fields.**

### New: content from the database, layout from one template

| | What | Where | Who changes it |
|---|---|---|---|
| **Content** | handbook title, intro, Studienverlaufspläne, section titles + intro/outro, module fields | DB (`Handbook`, `Section`, `ModuleEdition`) | admin, in the UI |
| **Layout** | document class, fonts, cover design, table of contents, module page table, "each chapter starts on a new page" | **one template** per format | developer, once |

Export = template + content → `.tex` → PDF (later: Typst template, same content).

```
template (fixed)                    content (from DB)
──────────────────                  ─────────────────────────
preamble, cover layout   ← fills ←  Handbook: title, subtitle, issue_date
table of contents
intro block              ← fills ←  Handbook.intro (incl. Studienverlaufspläne)
for each Section:
  chapter or section     ← uses  ←  Section.heading_level + title
  intro / outro          ← fills ←  Section.intro / outro
  new page rule          (template decides, no field)
  module page layout     ← fills ←  ModuleEdition fields
end of document
```

### What changes compared to the old system

| Old | New |
|-----|-----|
| `\newpage` typed in an Extro | Template rule (e.g., new page after each section); no field |
| `\chapter{…}` hidden in an Extro | `Section#heading_level`; template prints chapter or section |
| Header / Footer as DB records | Template. The old Header is the starting point, so the new PDF looks like the old one |
| Intro as raw LaTeX | `Handbook` fields: `title`, `subtitle`, `issue_date`, `intro` |
| Staff types LaTeX | Staff types text; lists and simple tables as Markdown |
| `\pageref` ("see page 7") | Link to the heading |

```admonish question "Ask the staff"
Do you ever change layout for one handbook only (a page break in one place, a special heading)? If yes, the template needs a small hook for it.
```

---

## Draft vs Official

| | Draft PDF | Official PDF |
|---|---|---|
| Old | Draft PDF icon, `draft=1` | PDF icon |
| `ModuleEdition`s included | all statuses, each marked with its status | `published` only |
| Empty sections | shown | omitted |
| Watermark | "Entwurf / Draft" | none |
| `Handbook` status | any | `published` (for viewer / public); admin may preview a draft `Handbook` |

- Publishing a `Handbook` with unpublished `ModuleEdition`s lists them first: they will be missing from the Official PDF.
- Order: `Section` position, then `SectionEntry` position.
- Labels (LV‑Nr., LP, Dauer …) in the `Handbook`'s language; module text in the `ModuleEdition`'s language.

## Single Module PDF

- Same module page as in the handbook, standalone (old: `pdf` per row).
- Status rule as above: public only for `published`.

## Check All Modules Render

- Renders every `ModuleEdition` of the `Handbook` separately and lists the ones that fail, with the error (old: "Check PDF generation of all modules").
- Needed because one broken module breaks the whole PDF.

## Public Pages

Old Output html/JSON is used by external websites. New equivalent:

| Old script | New |
|-----------|-----|
| `web_display_toc.php`, `web_page_display_toc.php` | Handbook page: TOC with links to modules (full page + embeddable fragment) |
| `web_display_course.php`, `web_page_display_course.php` | Module page (full page + embeddable fragment) |
| `json_code.php` | JSON: list of `CurriculumModule`s |
| `json_course.php` | JSON: one `ModuleEdition` |

- URLs by program `short_name` + term, module `code` + term. Default term: newest published.
- Published only. Drafts need a login (old `draft=1` showed drafts to anyone).
- No `l=de|en` parameter: each `ModuleEdition` has one language. No `encoding=latin1`: UTF‑8 only.

```admonish question "Ask the staff"
Which websites use the old html/JSON scripts? The new URLs differ; those pages need updating, or old URLs need redirects.
```

---

## Formats

- **PDF via LaTeX first**: matches the existing look.
- **LaTeX source** download for the admin (old Output → Latex).
- **Typst** later: same content, second template.
- Template uploadable by admin: [future extension](10-future-extensions.md).

---

## Implementation Notes

- **Service:** `Handbook::Exporter` renders one `Handbook` or one `ModuleEdition` into one format with one filter (`draft` / `official`).
- **Markdown → LaTeX / Typst:** pandoc, field by field, then inserted into the template. Never put raw text into the template unescaped (`%`, `&`, `_`).
- **Template:** start from the old Latex Header (packages, settings) and the old module page layout; compare the first new PDF with an old one.
- **Check render:** compile each module page alone; collect errors instead of stopping.
- **Runtime:** a full handbook PDF can take seconds; consider a background job and a download link.
- **Public JSON:** read‑only, published only; plain fields, no rendering.