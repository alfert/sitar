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

The curved arc under a group of Sargam letters is **not** a musical tie/slur,
and it is **not** a copy of LilyPond's beaming. It is a **per-beat grouping
bracket**:

- **One arc = one beat = one quarter note** of musical time.
- The number of note heads under the arc shows how that beat is subdivided:

| notes under one arc | meaning      |
| ------------------- | ------------ |
| 1                   | (no arc — a plain quarter note) |
| 2                   | eighth notes |
| 3                   | triplet      |
| 4                   | sixteenths   |
| 5                   | quintuplet   |
| …                   | …            |

So notes are grouped by **which beat they start in**; a beat containing 2+ note
heads gets a single arc spanning its first→last note. A beat with one note (a
quarter, or a longer note that starts the beat) gets no arc.

This is **independent of beaming**. Example: in 4/4, `M8 M P P D D` is one beam
of six eighths in the Melody staff, but rhythmically it is **3 beats** → **3
arcs** (M-M, P-P, D-D). Grouping by beam (an earlier mistake) drew one wrong arc
over all six.

(References: `sargam-rhythm.jpeg` — the definitive rule, "Rhythmic Notation",
and `raag-yaman-kalyan-original.jpeg`. Josh Feinburg, sitar method.)

Beat length is fixed at a quarter note (`sargam-beat-length = 1/4`). Beat index
of a note = `floor(absoluteMoment / 1/4)`, which keeps partial measures
(`\partial`) and compound talas (`\tintal`, `\jhaptal`) correct because the
absolute clock is shared by all notes.

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

### ✅ Group by BEAT (current mechanism)

Engraver: `Sargam_beat_arc_engraver`. The arc is per-beat, so it does **not**
look at beams at all. As each note head **or rest** is acknowledged, it is
bucketed by the beat it starts in:

```scheme
(beat (inexact->exact (floor (/ (ly:moment-main (ly:context-current-moment context))
                                1/4))))
```

At `finalize`, every beat bucket with **2+ events** gets one arc bound
first→last event of that bucket. Verified: 6 eighths in 4/4 → 3 arcs;
8 eighths → 4 arcs; triplet/sixteenth buckets; dotted-8 + 16 per beat; half note
gets no arc; `\partial` pickup beat; `\tintal` and `\jhaptal` talas; multi-staff.

### ✅ Rests participate in the arc, rendered as a dash (—)

Per `sargam-rhythm.jpeg`, a rest is one subdivision of its beat: `S8 r8` is two
subdivisions and is arced (`S —`); `r16 r16 r16 S16` is four subdivisions
(`— — — S`). So the engraver **also acknowledges `rest-interface`** grobs and
buckets them by beat exactly like note heads. A **`Tie` can bind LEFT/RIGHT to a
Rest grob** (verified), so the arc spans note→rest, rest→note, etc.

The rest glyph is replaced by an em-dash via `sargamRestStencil`
(`\override Rest.stencil`), matching the bold letter style. A full-beat (quarter)
rest is a lone dash with no arc. Note: `\chik` is a quarter rest with a tickmark,
so it now shows as tickmark-over-dash — which reads correctly as a stroke on an
empty beat.

#### ❌ Earlier dead end: group by beam (`beam-event`, then Beam grob)

First we listened for `beam-event` (LEFT/RIGHT) — works only for explicit `[ ]`
beams; **auto-beams emit no `beam-event`**. Then we acknowledged the **Beam
grob** instead (handles both beam kinds via `stem → 'note-heads`, reading at
`finalize` because explicit beams' stems attach incrementally).

Both were **musically wrong**: a beam can cover several beats (e.g. 6 eighths
under one beam in 4/4), but the arc must be **one per beat**. Abandoned in favor
of beat bucketing. (Kept here so we don't reintroduce it.)

---

## Current status

- **Per-beat arcs: working** in single-staff and multi-staff. One arc per beat
  (quarter note); the event count under it is the subdivision. Matches
  `sargam-rhythm.jpeg`. Independent of beaming, so auto-beams, explicit beams,
  and unbeamed notes all behave correctly.
- **Rests participate** and are drawn as dashes (—); e.g. the last bar of the
  first Gat (`G — G R — R S`) renders like the reference.
- Verified: 6 eighths → 3 arcs; 8 eighths → 4 arcs; triplets; sixteenths;
  dotted-8+16; half note (no arc); `\partial` pickup; `\tintal`/`\jhaptal`;
  note+rest, rest+note, and `— — — S` (3 sixteenth rests + note) beats.
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

## NoteColumns in Sargam (verified viable; deferred)

`SargamVoice` currently has **no NoteColumn**, which is why **manual slurs are
invisible** (a Slur attaches to a NoteColumn). We may want manual slurs later
for **meend / glissando** notation.

Tested adding both engravers to `SargamVoice`:

```lilypond
\context {
  \SargamVoice
  \consists Rhythmic_column_engraver   % creates NoteColumn (NOT "Note_column_engraver", which doesn't exist)
  \consists Slur_engraver
}
```

Result: **non-breaking** — the grouping arcs and horizontal spacing are
unchanged, and **manual slurs `( )` now render** (verified with `D8( D)`).

**Decision:** do NOT add this yet. There is no consumer for slurs in the current
notation, so we avoid changing the core context without an immediate need.
Enable it (the snippet above) when we implement meend/glissando.

## Key source references (local LilyPond checkout)

- `lily/slur-engraver.cc` — Slur attaches to NoteColumn (why slurs vanish here).
- `lily/rhythmic-column-engraver.cc` — the engraver that makes `NoteColumn`.
- `lily/tie.cc`, `lily/staff-symbol-referencer.cc` — why auto Tie positioning
  fails with `line-count = 0`.
- `lily/pitch-squash-engraver.cc` — squashing behavior.

## How to verify

```bash
cd sitar
lilypond raag-yaman-kalyan.ly && open raag-yaman-kalyan.pdf   # multi-staff
lilypond beat-arc-test.ly      && open beat-arc-test.pdf      # single-staff cases
```

Look for one arc under each beamed group; the number of letters under the arc
should equal the subdivision (2 = eighths, 3 = triplet, 4 = sixteenths).
