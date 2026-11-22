# Overview

A **Modulhandbuch** (module handbook) is the official catalog of a study program
for one term: which modules are offered, grouped into sections, with one
description per module (content, ECTS, cycle, prerequisites, …). It is published
as a PDF and on the department websites.

## Why a rebuild

Today the handbook lives in a separate legacy system:

- the same screens are duplicated per role tab (Course, StudDekanin, Modulhandbuch, Dozent)
- every module field exists twice (DE + EN), although usually only one is filled
- the semester copy duplicates everything, with no record of where it came from
- LaTeX layout is mixed with the data

The new handbook moves into MaMpf: one screen per thing, roles decide what is
shown, it reuses MaMpf's `Term` and `User`, and export templates are separate
from the data.

## Scope

- **In:** master data (study programs, curriculum modules), per-term module
  descriptions, handbook assembly, review & publish, cloning to the next term,
  PDF/LaTeX export, public pages, migration of the old data
- **Out (for now):** Dozent self-editing (see [Roles & Permissions](00c-roles-and-permissions.md)), link to MaMpf `Lecture`, LSF/heiCO sync

## How to read this chapter

| If you want to… | Read |
|---|---|
| understand the new design | [New Handbook](00a-new-handbook-overview.md) → [Domain Model](01-domain-model.md) |
| know how the old system works | [Old Handbook System](00b-old-handbook-overview.md) |
| see who can do what | [Roles & Permissions](00c-roles-and-permissions.md) |
| follow a task step by step | [End-to-End Workflow](10-end-to-end-workflow.md) (11–19) |
| click through the screens | [Mockups](mockups-index.md) |
