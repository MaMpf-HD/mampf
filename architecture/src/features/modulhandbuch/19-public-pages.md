# Flows & Screens: Public Pages

Published handbooks and modules on the web, without login. Replaces the old Output html/JSON scripts.

| Who | Sees |
|-----|------|
| Anyone (no login) | published `Handbook`s, published `ModuleEdition`s |
| Logged in, may edit the handbook | the same + **draft preview** |

Roles: see [Roles & Permissions](00c-roles-and-permissions.md).

**URLs** (design, stable):

| Page | URL |
|------|-----|
| Handbook (TOC) | `/modulhandbuch/<program short_name>/<term>` |
| Handbook, newest published term | `/modulhandbuch/<program short_name>` |
| Module | `/modulhandbuch/module/<code>/<term>` |
| Module, newest published term | `/modulhandbuch/module/<code>` |
| Embeddable fragment | same URL + `?embed=1` |
| JSON | same URL + `.json` |

---

## Flows

**Pu1. Student reads the handbook**
1. Institute website → link → handbook page (S1), newest published term.
2. Clicks a module → module page (S2).
3. **Official PDF** button for the whole handbook.

**Pu2. Older term**
- Term selector on S1 / S2 → any term with a published handbook / module.

**Pu3. Website embeds the TOC** (old `web_display_toc.php`)
- The website includes the `?embed=1` fragment: TOC only, no MaMpf layout.

**Pu4. Program consumes JSON** (old `json_code.php`, `json_course.php`)
- Handbook JSON: program, term, sections with module code + name + link.
- Module JSON: all printed fields of the `ModuleEdition`.
- Module list JSON: all active `CurriculumModule`s (code, title, subject area).

**Pu5. Preview a draft**
- Logged in, with edit rights on the handbook → handbook page shows **Show draft** toggle → draft content with a "Draft" banner. Never visible without login (old `draft=1` hole closed).

**Pu6. Old links**
- Old `…/OUTPUT/web_page_display_course.php?code=IMI1` → redirect to `/modulhandbuch/module/IMI1`.
- Old `…?id_modulhandbuch=13` → redirect via a mapping of old ids to `short_name`.

**Pu7. Get a link to share**
- Handbook editor → ⋯ → **Public link** → copy URL / embed URL.

---

## Screens

### S1. Public handbook page

```
Modulhandbuch Informatik BSc 100%                  Term [WS 2026/27 ▾]  [Official PDF]
Fassung vom 15.10.2026 zur Prüfungsordnung vom 26.03.2015 …

Contents
1 Pflichtbereich
  1.1 Pflichtmodule Informatik
      IPI   Einführung in die Praktische Informatik      8 LP
      IPK   Programmierkurs                             4 LP
      …
  1.2 Pflichtmodule Mathematik
      …
2 Wahlbereich
  …
```

- Front matter (intro, Studienverlaufspläne) above or as a collapsible "About this handbook".

### S2. Public module page

```
IACO · Applied Combinatorial Optimization          Term [WS 2026/27 ▾]  [PDF]
LV-Nr. 1300282205 · 8 LP · one semester · every winter semester · English

Format          Lecture 4 SWS + Exercise course 2 SWS
Workload        240 h; thereof …
Usability       M.Sc. Data and Computer Science, M.Sc. Mathematik, …
Lecturers       Bogdan Savchynskyy
Learning goals  …
Topics          …
…
Listed in: Mathematik MSc, Informatik MSc DaCS, SciComp MSc (WS 2026/27)
```

### S3. Public link dialog

```
Public link · Informatik BSc 100%
Page    https://…/modulhandbuch/informatik-bsc-100            [Copy]
Embed   https://…/modulhandbuch/informatik-bsc-100?embed=1    [Copy]
JSON    https://…/modulhandbuch/informatik-bsc-100.json       [Copy]
⚠ Not published yet: the link shows the latest published term.
```

---

## Small Decisions

1. URLs use `short_name` and `code`, not database ids (old used ids).
2. Without a term, pages show the newest **published** term (old: newest version, incl. unreleased in some cases).
3. Old script URLs redirect; the list of external websites still needs to come from the staff.
4. No `l=` and `encoding=` parameters: one language per module, UTF‑8 only.
