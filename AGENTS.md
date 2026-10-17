# AGENTS.md - Sargam Notation System for LilyPond

## Project Overview

This is a custom **Sargam notation system** for Indian classical music using LilyPond. The system extends LilyPond to support Indian pitch names (Sa, Re, Ga, Ma, Pa, Dha, Ni) and provides custom engravers for rendering sitar/raag notation with specialized note heads, octave dots, and voice line connections.

**Key Components:**

- `raag.ly` - Core Sargam library with custom engravers, pitch definitions, and rendering functions
- `paper.ily` - Global paper and font configuration (Optima, MuseJazzText, etc.)
- Individual composition files (e.g., `raag-yaman-kalyan.ly`) that include raag.ly

## Build & Compilation Commands

### Single File Compilation

```bash
cd ~/src/lily/sitar
lilypond raag-yaman-kalyan.ly
```

### Other Useful Commands

```bash
# View generated PDF (macOS)
open raag-yaman-kalyan.pdf

# Clean all PDF outputs
rm *.pdf

# Syntax validation with detailed logging
lilypond --loglevel=DEBUG raag-yaman-kalyan.ly

# Check LilyPond version (should be 2.26.x)
lilypond --version
```

### VSCode Integration

- **Build command:** `Cmd+Shift+B` (uses tasks.json default build task)
- The task runs `lilypond ${fileBasename}` in the file's directory
- Problem matcher: see "Error Handling → VSCode Integration" below

## File Structure

```
raag.ly                  # Core Sargam library (handle with care!)
paper.ily                # Global paper/font configuration
raag-yaman-kalyan.ly     # Example composition
raad-demo.ly              # Demo file
hindols-raag.ly           # Composition with segno repeat, meends, chiks
*-test.ly                 # Feature tests (see "Testing After Engraver Modifications")
*.pdf                     # Generated outputs (git-ignored)
```

**Note:** PDF files are git-ignored by design. Only source `.ly` files are tracked.

## Code Style Guidelines

### Version Declaration

Always start files with a version declaration:

```lilypond
\version "2.26.0"  % Preferred
% OR
\version "2.26"    % Also acceptable
```

Existing files predate this: most use `"2.24.0"`, some older compositions use `"2.18.0"`. Migrate to 2.26.0 when touching a file.

### Include Order

Follow this standard order:

```lilypond
\version "2.26.0"

\include "paper.ily"
\include "raag.ly"

% Variable definitions
melodyGatI = \relative S' { ... }
textI = \lyricmode { ... }

% Score
\score { ... }
```

### Naming Conventions

**Music variables:** camelCase with Roman numerals

```lilypond
melodyGatI = \relative S' { ... }
raagMhegGatI = \relative S' { ... }
```

**Text/lyrics:** camelCase

```lilypond
textI = \lyricmode { ... }
textII = \lyricmode { ... }
```

**Chords:** camelCase

```lilypond
chordSymbols = \chordmode { ... }
```

**Scheme functions:** kebab-case

```scheme
#(define (head-name-from-pitch pitch) ...)
#(define (stack-note notename super-dots sub-dots) ...)
```

### Sargam Pitch Names

Defined in `raag.ly`, based on C major scale:

**Uppercase = natural pitches:**

- `S` = Sa (C) - Tonic
- `Re` = Ri (D natural) - Supertonic
- `G` = Ga (E natural) - Mediant
- `M` = Ma sharp (F#) - Augmented 4th
- `P` = Pa (G) - Dominant
- `D` = Dha (A natural) - Submediant
- `N` = Ni (B natural) - Leading tone

**Lowercase = flat variants:**

- `re` = Ri komal (D flat)
- `g` = Ga komal (E flat)
- `m` = Ma shuddha (F natural)
- `d` = Dha komal (A flat)
- `n` = Ni komal (B flat)

**Important:** Use `\language "sargam"`  to enable these pitch names.

**Ma variants (input vs. print):** In the LilyPond INPUT, `m` = Ma shuddha (F)
and `M` = Ma tivra (F#) — lowercase vs. uppercase is how the two are told apart.
In the PRINTED sargam (Bhatkhande convention) BOTH print as a capital **M**;
tivra Ma additionally gets a short vertical bar centered on top of the M
(`sargamBarredM`). More generally, printed shuddha (natural) swaras are CAPITAL
(S R G M P D N) and komal (flat) swaras are lowercase (r g d n), independent of
the input letter case — the printed letter is derived chromatically from Sa.

**Transposition (`\sargamSa`):** Sargam letters are relative to Sa (the tonic),
computed CHROMATICALLY (by semitone from Sa), so they are independent of the
absolute pitch and of enharmonic spelling. By default Sa = C. If a staff is
written inside a `\transpose` (e.g. `\transpose S Re` to sound in D), the sargam
letters would otherwise shift; set `\sargamSa` to the ACTUAL sounding pitch of
Sa so the letters (and octave dots) stay correct:

```lilypond
\new SargamVoice {
  \sargamSa Re            % Sa sounds as Re (D) on this transposed staff
  \transpose S Re { \myMelody }
}
```

`\sargamSa` sets the `NoteHead.sargam-sa` grob property (a pitch), read by
`sargamHeadStencil`. Non-transposed SargamStaves need nothing (default Sa = C).

### Comments

Use consistent comment styles:

```lilypond
% Single-line comment

%% Section Header
%% SARGAM Notation

%%%%%%%%%%%%%%%%%%%%
%% MAJOR SECTION
%%%%%%%%%%%%%%%%%%%%

code | % Inline explanation after code
```

### Indentation and Formatting

- Use **2 spaces** for indentation (LilyPond standard)
- Align nested contexts for readability
- One statement per line generally
- Use `|` for explicit bar lines
- Use `\break` for forced line breaks in layout

```lilypond
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key D \major
      \transpose S Re {
        \tintal
        \melodyGatI
      }
    }
  >>
}
```

### Scheme Code Style

- Prefix inline Scheme with `#`
- Use `#{ ... #}` for LilyPond syntax within Scheme
- Follow Lisp-style parenthesis conventions
- Reference existing patterns in `raag.ly` for complex engravers

```scheme
#(define (sargamHeadStencil grob)
   (let* ((pitch (ly:event-property (event-cause grob) 'pitch))
          (octave (ly:pitch-octave pitch)))
     (grob-interpret-markup grob
       (make-lower-markup 0.5
         (stack-note note-number super-dots sub-dots)))))
```

## Sargam Notation System Details

### Custom Note Heads

Note heads are rendered via the `sargamHeadStencil` function (raag.ly:196), which:

- Displays Sargam letter names (S, R, G, M, P, D, N) instead of traditional note heads
- Adds octave dots above/below note names
- Formats duration indicators (underlines, dashes)
- Renders **tivra Ma** (pitch `M`, F#) as a capital **M with a short vertical
  bar centered on top** (Bhatkhande convention); shuddha Ma (`m`, F) prints as a
  plain capital M. The bar is drawn by the `sargamBarredM` markup command, which
  measures the M's extent and centres the bar over it, so no special font is
  required and only tivra Ma changes.

### Octave Notation

- **Super-dots (above note):** Indicate higher octaves (taar saptak)
- **Sub-dots (below note):** Indicate lower octaves (mandra saptak)
- **Number of dots:** Corresponds to octave displacement from middle register

Example: A note with 2 dots above is two octaves higher than middle register.

### Duration Notation in Sargam Staff

The `sargamHeadStencil` function applies visual indicators based on the note's
duration:

- **Eighth notes (dur-log 3):** underlined note name (e.g. `S̲`).
- **Quarter notes (dur-log 2):** no marking (bold letter only) — one beat.
- **Notes longer than a beat:** the letter is followed by **one em-dash (—) per
  extra beat**, with a small space before the first dash. This is computed from
  the note's *actual* duration (so dots count):
  - half note `S2` → `S —`
  - dotted half `S2.` → `S — —`
  - whole note `S1` → `S — — —`

  This matches the rest dash (a held beat reads the same as a rest beat) and is
  produced by `sargam-extra-beats` / `sargam-duration-postfix-markup`. Octave
  dots and the em-dash tail coexist. Rests follow the same rule (`r2` → `– –`).
- **Notes crossing a beat boundary:** the held part continues as a dash IN THE
  NEXT BEAT and counts under that beat's arc (sargam-rhythm.jpeg):
  `S4. S4.` → `S – S –` with the arc under `– S`; `D4 n8 D4 n8 P4` →
  `D | n D | – n | P`. Implemented by splitting notes/rests at beat boundaries
  (`Completion_heads_engraver` in SargamVoice, `Completion_rest_engraver` in
  SargamStaff, `completionUnit = 1/4`). `Sargam_continuation_engraver` marks
  the split-off heads (`sargam-continuation`); they draw as `–` and never carry
  bols or start/end a meend. A note starting ON a beat stays whole for a
  power-of-two number of beats (`S2` → one head `S —`).

### Special Commands

```lilypond
\chik 4    % Chikari stroke (drone strings). REQUIRED duration: \chik 4, \chik 8…
           %   A note (not a rest), tagged 'chik. Normal Staff: slash head on the
           %   middle line (guitar strumming style). Sargam: letter "C". Does not
           %   shift the \relative reference pitch.
\tintal    % 16-beat tala cycle (4+4+4+4)
\jhaptal   % 10-beat tala cycle (2+3+2+3)
```

### Bols (mizrab / plectrum strokes)

Right-hand stroke annotations in a flat row BELOW the staff. Generic (like
violin bowing or guitar picking), so they render on BOTH the normal notation
Staff and the SargamStaff. All three are written PREFIX (they mutate the note
event, the only mechanism that reaches both staves; a postfix `G\da` cannot,
because the normal staff strips articulations before the note head is engraved).

```lilypond
\da G            % da: single downstroke, drawn as a vertical bar  |
\ra Re           % ra: single upstroke,   drawn as a dash          —
\diri { M8 M }   % diri: fast down-up across TWO notes, caret/triangle ⌃
```

- `\da` / `\ra` wrap EXACTLY one note (error otherwise); set its `bol` event
  property to `'da` / `'ra`.
- `\diri` wraps EXACTLY two notes of ANY durations (16+16, 8+16, 16+8, 8+8, …).
  It tags the first note `diri = LEFT` and the last `diri = RIGHT`; pairing is
  explicit (from the wrap), NOT inferred from rhythm. Errors if not 2 notes.
- On a SargamStaff a diri pair therefore shows the beat-grouping arc (⌣) ABOVE
  the letters (rhythm) and the diri caret (⌃) BELOW (matches the book).

### Meend (glide)

```lilypond
\meend { S4 Re G M }        % one continuous glide over 2+ notes
\meend { P2 \da M4 G }      % \da marks a stroke needed inside the meend
```

- Normal Staff: slur over all notes plus a glissando line between each pair
  (added as articulations; SargamVoice has no Slur/Glissando engraver, so the
  Sargam side ignores them).
- SargamStaff: flat arc ABOVE the letters with rounded ends hooking onto the
  first and last note (OME Bhatkhande font style), drawn by `Meend_engraver`.
  The arc clears the tallest member including octave dots.
- Errors if fewer than 2 notes.

### Bol_arc_engraver (raag.ly, after `Sargam_beat_arc_engraver`)

Draws all bols (the `\da` bar `|`, the `\ra` dash `—`, and the `\diri` caret ⌃)
on ONE flat row. It reads the `bol` / `diri` event properties, then reuses a Tie
spanner ONLY as a positioning vehicle (parent-anchored to a note head so it
renders on both a normal Staff and the pitch-squashed SargamStaff), overriding
the Tie's `stencil`. The row is kept flat RELATIVE TO THE STAFF (not the note
head) via `sargam-bol-base`, which cancels the head's pitch so the bols form one
horizontal line at `sargam-bol-baseline` below the staff instead of drifting
with the melody. Consisted into both the `Staff` and `SargamStaff` contexts in
the `\layout` block.

`\da`/`\ra` are simple below-note markups with a high `outside-staff-priority`
(`sargamBolPriority`) so the bol row sits below everything else.

### Custom Contexts

**SargamVoice** (raag.ly:233)

- Voice context with pitch squashing and slash-style note heads
- Hidden stems, consists of Completion_heads_engraver (beat splitting) and
  Text_engraver
- Aliased to standard Voice for compatibility

**SargamStaff** (raag.ly:253)

- Staff with no staff lines (`line-count = #0`)
- Custom bar extent for visibility
- Overrides NoteHead.stencil with `sargamHeadStencil`
- Includes all RhythmicStaff engravers plus custom engravers
- Aliased to `RhythmicStaff` and `Staff`, so `\set Staff.…` commands such as
  `\submeasureBarsOn` work inside it

## Custom Engravers (Brief Documentation)

> For the design history, dead ends, and the *why* behind the current
> implementation, see `EXPERIMENT-LOG.md`.

### Sargam_beat_arc_engraver (raag.ly, defined just before `sargamHeadStencil`)

**Purpose:** Draws the **rhythmic grouping arc** under the Sargam letters.
**One arc = one beat (one quarter note).** The **number of events under one arc
encodes the subdivision of that beat** — and **rests count as events** (a rest
is drawn as a dash `—` and sits under the arc, just like a note):

| events under one arc | meaning      |
| -------------------- | ------------ |
| 1                    | (no arc — plain quarter note or full-beat rest) |
| 2                    | eighth notes (note+note, note+rest, …) |
| 3                    | triplet      |
| 4                    | sixteenths   |

This is **independent of beaming**. In 4/4, `M8 M P P D D` is one 6-note beam but
**three beats**, so it draws **three arcs** (M-M, P-P, D-D). And `G8 r8` is one
beat with two subdivisions, so it is arced (`G —`). See `sargam-rhythm.jpeg` for
the authoritative rule.

**Nested arcs:** if the events of a beat have UNEQUAL durations, every
half-beat holding two or more events also gets an inner arc (just under the
letters; the beat arc then sits lower). `S32 S S S r8` → inner arc under the
four 32nds, beat arc under all five (as in the book); `S8 S16 S16` → inner arc
under the two 16ths; `S8. S16` → beat arc only. Equal subdivisions (8ths,
16ths, triplets) never nest. Depths: `sargam-arc-depth`,
`sargam-inner-arc-depth`, `sargam-outer-arc-depth`.

**Status:** Working in single-staff and multi-staff, including rests. Triplets
and sixteenths produce arcs but still need visual polish (collisions with the
16th underline / octave dots).

**How it works:**

1. As each **note head OR rest** is acknowledged, bucket it by the beat it
   starts in: `beat = floor(absoluteMoment / 1/4)` (beat length = quarter note,
   `sargam-beat-length`). Using the **absolute** moment keeps `\partial` pickups
   and compound talas (`\tintal`, `\jhaptal`) correct.
2. At **`finalize`**, every beat bucket with **2+ events** gets ONE `Tie`
   grob bound LEFT = first, RIGHT = last event of that beat (a bound may be a
   note head or a rest — a Tie can bind to either).
3. It **anchors the tie's X and Y parent to the left event**
   (`ly:grob-set-parent!`) and sets explicit **`control-points`**. This bypasses
   LilyPond's automatic tie positioning, which fails in a `line-count = 0`,
   pitch-squashed staff. Without the forced parents/control-points the arc is
   invisible or escapes to another staff.

Rests are rendered as a dash via `sargamRestStencil` (`\override Rest.stencil`).

**Why a Tie and not a Slur:** in this context a manual Slur is invisible (slurs
attach to a `NoteColumn`, which `SargamVoice` does not create), while a Tie
binds to note heads and renders. See `EXPERIMENT-LOG.md`.

**Layout wiring** (already set in `raag.ly`'s `SargamStaff` context):

```lilypond
\consists Tie_engraver            % collects/draws the Tie grobs we create
\consists #Sargam_beat_arc_engraver
```

**Visual example:**

```lilypond
{ \time 4/4 G4 M8 M P P D D }   % beats 2,3,4 each hold 2 eighths -> three arcs
```

```
G   M M   P P   D D
   ⌣     ⌣     ⌣
```

### Testing After Engraver Modifications

After any change to `raag.ly`, compile ALL test files and compositions and
check the console for errors/warnings:

| file                  | checks                                                  |
| --------------------- | ------------------------------------------------------- |
| `meend-test.ly`       | meend arc above letters, slur + glissando on the Staff   |
| `chik-test.ly`        | chik slash heads, letter C, `\relative` continuity      |
| `beat-arc-test.ly`    | beat-grouping arcs                                      |
| `rhythm-test.ly`      | rhythm notation (compare with sargam-rhythm.jpeg)       |
| `nested-arc-test.ly`  | nested half-beat arcs, beat splitting of held notes     |
| `raag-yaman-kalyan.ly`, `hindols-raag.ly`, `raad-demo.ly` | real scores (regressions) |

Each test file states in its header comment what the output should look like.

**Visual check: use high resolution and crop.** Low-resolution previews
mislead: at ~110 dpi a meend arc 0.4 staff spaces above the letters looks as if
it sits ON them. Render with:

```bash
lilypond --png -dresolution=220 -dcrop -o /tmp/out file.ly
```

Check for:

- Unexpected note positioning
- Grob errors in console output
- Visual artifacts / collisions (arcs vs octave dots, bols, bar lines)

For geometry bugs, print the computed values (e.g. a temporary redefinition of
the stencil callback with `format #t ...` in a scratch copy) before changing
code: it separates "computed wrong" from "rendered/perceived wrong".

## Common Patterns & Score Structure

### Standard Three-Staff Layout

Most compositions use this pattern:

```lilypond
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key D \major
      \transpose S Re {
        \tintal
        \melodyGatI
      }
    }
    \new Staff {
      \set Staff.instrumentName = "Sargam Voice"
      \key D \major
      \transpose S Re {
        \tintal
        \new SargamVoice {
          \melodyGatI
        }
      }
    }
    \new SargamStaff = "sargam-staff-id" {
      \set SargamStaff.instrumentName = "Sargam Staff"
      \key D \major
      \tintal
      \new SargamVoice = "voice-id" {
        \melodyGatI
      }
    }
    \new Lyrics \lyricsto "voice-id" { \textI }
  >>
  \header {
    title = "Raag Name"
    composer = "Composer Name"
  }
}
```

### Transposition

Use `\transpose S Re { ... }` to shift from C (Sa) to D (Re), etc.
Common transpositions maintain Sargam logic while fitting instrument ranges.

### Section Labels and D.S. al Fine

Name sections with `\sectionLabel "Sthaayi"` (not `\mark "..."`). For the gat
form "sthaayi, antara, back to sam of the sthaayi" use LilyPond's segno repeat
(see `hindols-raag.ly`): it prints the segno, Fine and "D.S. al Fine" itself.

```lilypond
melodyGatII = \relative S' { ... }       % antara, defined FIRST
melodyGatI = \relative S' {
  \partial 4*4 ...                       % mukhda pickup (before the segno)
  \repeat segno 2 {
    \repeat volta 2 { ... }              % sthaayi
    \volta 2 \fine
    \volta 1 \melodyGatII                % antara, then D.S. al Fine
  }
}
```

Use D.S. (Dal Segno), not D.C., when the jump target is not the very beginning
(e.g. after a pickup). Do NOT use explicit `\fine` mid-piece (warns "music after
\fine" outside `\repeat segno`) or `\textEndMark "Fine"` (text marks print once
PER STAFF when the music variable is shared by Staff and SargamStaff; segno,
Fine and jumps are de-duplicated).

### Layout Overrides

Custom layout modifications are defined in `raag.ly` (the `\layout` block near the end). Use existing patterns as templates:

```lilypond
\layout {
  \context {
    \SargamStaff
    \consists Tie_engraver
    \consists #Sargam_beat_arc_engraver
  }
}
```

## Error Handling

### Error Message Format

LilyPond errors follow this pattern:

```
filename.ly:42:15: error: syntax error, unexpected NOTENAME_PITCH
```

Format: `filename:line:column: severity: message`

### VSCode Integration

The `tasks.json` problem matcher is configured to parse both English and German error messages:

- `error` / `Fehler` → Error severity
- `warning` / `Warnung` → Warning severity

### Common Issues

1. **Missing include files**
   - Check relative paths: `\include "paper.ily"`
   - Ensure raag.ly is in the same directory

2. **Pitch name typos**
   - See "Sargam Pitch Names" above for the full letter table

3. **Bracket/brace mismatches**
   - LilyPond: `{ }` for music, `< >` for chords
   - Scheme: `( )` for all expressions

4. **Grob property errors**
   - Property names are case-sensitive: `NoteHead.stencil` not `notehead.stencil`
   - Use `\override` for grob properties, not direct assignment

5. **Variable name collides with a pitch name**
   - Under `\language "sargam"`, `m`, `d`, `g`, `n`, `S`, `P`, ... are pitches;
     a variable called `m` gives "syntax error, unexpected NOTENAME_PITCH".
     Use descriptive names (`melodyI`).

6. **`;` comment after a top-level `#(define ...)`**
   - Outside the Scheme expression the LilyPond parser reads `;` as an
     "undefined character". Use `%` there; `;` only works inside `#( ... )`.

7. **`\set Staff.…` has no effect in a custom staff**
   - Only works if the context has `\alias Staff` (SargamStaff does).

### Debug Mode

For verbose output with detailed diagnostics:

```bash
lilypond --loglevel=DEBUG raag-yaman-kalyan.ly
```

---

## Summary for AI Agents

**Primary Task:** When working with this codebase, you are modifying LilyPond music notation files for Indian classical music. The system uses custom Scheme engravers and specialized Sargam notation.

**Key Priorities:**

1. Maintain compatibility with LilyPond 2.26.x
2. Follow Sargam pitch naming conventions (S, Re, G, M, P, D, N)
3. Use camelCase for music variables with Roman numerals
4. Test all changes by compiling to PDF
5. Be extremely careful when modifying `raag.ly` engravers - they are fragile

**Workflow:**

1. Read existing files to understand patterns
2. Make changes following style guidelines above
3. Compile with `lilypond <filename>.ly`
4. Verify PDF output is correct
5. Document any new engraver behavior or custom functions

**When in doubt:** Consult `raag.ly` for implementation patterns and existing engravers. The codebase is highly specialized, so following established patterns is critical for success.

If you need to check the lilypond source code, it is available under $HOME/src/lily/lilypond.
Caveat: that checkout is from July 2024 and predates 2.26 features (e.g.
submeasure bars). For the exact installed version read
`/opt/homebrew/Cellar/lilypond/2.26.0/share/lilypond/2.26.0/{ly,scm}`.
