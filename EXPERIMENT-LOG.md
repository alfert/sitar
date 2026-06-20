# Sargam Grouping-Arc — Experiment Log

A running, curated record of what we tried for the **rhythmic grouping arc**
under beamed Sargam note letters, what worked, what didn't, and **why**.
Keep this lean: add findings, delete things that turn out wrong. The goal is to
never repeat a dead end.

> Supersedes the earlier notes `SESSION-SUMMARY.md`,
> `NEXT-SESSION-CHECKLIST.md`, `TIE-POSITIONING-LESSONS-LEARNED.md` (deleted —
> several of their conclusions were wrong, see below).

---

## What the arc actually means (corrected understanding)

The curved arc under a group of Sargam letters is **not** a musical tie/slur.
It is a **grouping bracket that encodes the rhythmic subdivision** — the Sargam
equivalent of a Western beam:

| notes under one arc | meaning      |
| ------------------- | ------------ |
| 2                   | eighth notes |
| 3                   | triplet      |
| 4                   | sixteenths   |
| …                   | …            |

Therefore the engraver draws **exactly one arc per beamed group**, spanning the
whole group (first note → last note). The *count* of letters under the arc
communicates the rhythm. (Reference: Josh Feinburg, "Composition in
Medium-Fast Tintal", `raag-yaman-kalyan-original.jpeg`.)

The up/down stroke marks (bols, the `^` / `v` row under the letters) are a
**separate** feature, not yet implemented.

---

## Context that makes this hard

The `SargamStaff` is deliberately unusual:

- `StaffSymbol.line-count = 0` (no staff lines)
- note heads are custom **text** stencils (`sargamHeadStencil`), letters S/R/G…
- notes are **pitch-squashed** to position 0 (`Pitch_squash_engraver`)
- stems are hidden

This breaks LilyPond's normal vertical positioning for ties and slurs.

---

## Findings (what works / what doesn't)

### ❌ MYTH (from old docs): "Slurs work, Ties don't"

The opposite is true in this context. Verified with manual `( )` and `~` in a
`SargamStaff` (isolation test):

- **Manual Slur `( )` → invisible.** A Slur attaches to a **NoteColumn**
  (`Slur_engraver::acknowledge_note_column`). `SargamVoice` has no
  `Note_column_engraver`, so the slur has no anchor and is dropped.
- **Manual Tie `~` → renders.** A Tie binds directly to note **heads**, which
  exist. So ties are visible; their only problem is *positioning*.

Conclusion: **use a Tie grob**, not a Slur.

### ❌ Auto-positioned Tie/Slur → invisible / misplaced

With `line-count = 0` + pitch squashing, `Staff_symbol_referencer::get_position`
has no valid Y reference (debug showed the tie's Y-parent = `()`), so an
automatically positioned arc collapses to nothing or flies off.
Tuning `staff-position`, `Y-offset`, or `details.*` does **not** fix this — they
are interpreted in the wrong coordinate space.

### ✅ Tie grob with FORCED `control-points`

Setting explicit Bezier `control-points` on the Tie **bypasses** the broken
positioning algorithm entirely. The arc then renders reliably.
Control points are computed lazily (grob callback) once X positions are known,
from the X-extents of the first/last note heads (`sargam-arc-control-points`).

### ✅ Anchor the Tie's X and Y parent to the left note head

The forced control points are interpreted **relative to the tie's parents**.
In a **single-staff** score this happened to be fine, but in a **multi-staff**
score (Melody staff + SargamStaff) the Y reference was ambiguous and the arc
rendered far away / not under the letters. Fix:

```scheme
(ly:grob-set-parent! tie Y left-nh)
(ly:grob-set-parent! tie X left-nh)
```

This makes the arc land under the Sargam letters in **every** layout.
This was the specific bug behind the old "ties escape to other staves" report.

### ✅ Detect groups by acknowledging the Beam GROB, create ties at `finalize`

This is the mechanism for finding the groups, and it handles **both explicit
`[ ]` beams and automatic beams** — which was the whole point.

Earlier attempts listened for `beam-event` (`span-direction` LEFT/RIGHT). That
only works for **explicit** beams; **auto-beams emit no `beam-event`**, so
auto-beamed groups got no arc. (Verified: with auto-beams a probe sees a Beam
*grob* acknowledged but never a `beam-event`.)

Fix: **acknowledge the `Beam` grob** (`beam-interface`). Both explicit and auto
beams produce a Beam grob whose member **stems** lead to the note heads
(`stem → 'note-heads`). One arc per Beam grob, bound first→last note head.

Timing detail: an explicit beam's `stems` array is **not fully populated** at
the `stop-translation-timestep` when the beam first appears (only 1 stem is
attached then; reading it there gave arcs for auto-beams but **broke explicit
beams**). Both kinds are complete by **`finalize`**, so we collect all Beam
grobs during the run and create the ties in `finalize`. Verified working for:
explicit pairs, auto-beam groups (incl. the 2+4 split LilyPond picks in 4/4),
explicit 3-note beams, and beams broken by rests.

Helper `beam-end-note-heads` returns `(first-nh . last-nh)` for a beam, or `#f`
if it has < 2 stems (which also filters out phantom/partial Beam grobs).

---

## Current status

- **Eighth-note pairs (2 notes): working** in both single-staff and multi-staff.
  This is the primary target and matches the reference.
- **Auto-beams now also produce arcs** (via the Beam-grob mechanism), so the
  normal "let LilyPond beam" workflow works — explicit `[ ]` is not required.
- **Triplets (3) and sixteenths (4): arcs are produced**, but rendering still
  needs polish — at tight spacing / line-ends the arc can collide with the
  16th-note underline and with octave dots. Not yet refined.
- Debug `log-exprs` output removed; the experimental dual
  slur-engraver / `SargamStaffTies` context removed; one `SargamStaff` remains.

## Open / next

- Polish triplet & sixteenth arcs (collision with underlines / octave dots).
- Tighten horizontal spacing of beamed Sargam groups so pairs sit close
  together as in the book (currently spread when aligned under a Melody staff).
- Bols (up/down stroke marks) under the letters — separate feature.

## Key source references (local LilyPond checkout)

- `lily/slur-engraver.cc` — Slur attaches to NoteColumn (why slurs vanish here).
- `lily/tie.cc`, `lily/staff-symbol-referencer.cc` — why auto Tie positioning
  fails with `line-count = 0`.
- `lily/pitch-squash-engraver.cc` — squashing behavior.

## How to verify

```bash
cd sitar
lilypond raag-yaman-kalyan.ly && open raag-yaman-kalyan.pdf   # multi-staff
lilypond beam-tie-test.ly      && open beam-tie-test.pdf      # single-staff cases
```

Look for one arc under each beamed group; the number of letters under the arc
should equal the subdivision (2 = eighths, 3 = triplet, 4 = sixteenths).
