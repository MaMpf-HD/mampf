# Flows & Screens: History

Who changed what and when.

```admonish warning "⚑ Open"
These flows assume full history (old → new per change). With only "created/updated by", Hi1 shows one line and Hi3 / Hi4 are not possible.
```

---

## Flows

**Hi1. See the history of a record**
1. Any edit / detail page → **History ▸**.
2. Timeline, newest first: who, when, what (fields changed, status, structure).
3. Click an entry → old → new per field; long text as word diff.

**Hi2. See who changed it last**
- Lists show **Last changed** (date, name); "copied" if unchanged since cloning, "imported" after migration.

**Hi3. Why is it back to created?**
1. Description → History.
2. Entry: "15.10. P.-Schmid · literature changed · status published → created".

**Hi4. What happened to a handbook?**
1. Handbook editor → ⋯ → **History**.
2. Structure events: "IAD removed from Wahlmodule Informatik", "Section 'Anwendungsgebiet' added", "published".

**Hi5. Filter**
- History panel filter: all · content · status · structure.

---

## Screens

### S1. History panel

```
History                                     [all ▾]
● 15.10.2026 14:02  P.-Schmid
   Literature changed                                   ▸ show diff
   Status published → created
● 02.10.2026 09:11  P.-Schmid
   Status checked → published
● 01.10.2026 16:40  P.-Schmid
   Status created → checked
● 20.09.2026 10:05  system
   Copied from SoSe 2026 (Prepare a term)
```

### S2. Entry detail

```
15.10.2026 14:02 · P.-Schmid
Literature
- Korte, Bernhard H. Combinatorial optimization. Berlin: Springer, 2008.
+ Korte, Bernhard H. Combinatorial optimization. Berlin: Springer, 2011.
Status   published → created
```

### S3. Handbook history

```
History · Informatik BSc 100% · WS 2026/27      [structure ▾]
● 16.10.  P.-Schmid  published
● 15.10.  P.-Schmid  IITS3 added to Wahlmodule Informatik
● 15.10.  P.-Schmid  ILat removed from Wahlbereich Übergreifende Kompetenzen
● 20.09.  system     cloned from SoSe 2026
```

---

## Small Decisions

1. Cloning and migration write one entry per record ("copied from …", "imported"), not per field.
2. A drag that moves many rows is one entry ("reordered Wahlmodule Informatik").
3. Viewers do not see history.
