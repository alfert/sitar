# AGENTS.md - Sargam Notation System for LilyPond

## Project Overview

This is a custom **Sargam notation system** for Indian classical music using LilyPond. The system extends LilyPond to support Indian pitch names (Sa, Re, Ga, Ma, Pa, Dha, Ni) and provides custom engravers for rendering sitar/raag notation with specialized note heads, octave dots, and voice line connections.

**Key Components:**

- `raag.ly` - Core Sargam library with custom engravers, pitch definitions, and rendering functions
- `../paper.ily` - Global paper and font configuration (Optima, MuseJazzText, etc.)
- Individual composition files (e.g., `raag-yaman-kalyan.ly`) that include raag.ly

## Build & Compilation Commands

### Single File Compilation

```bash
# From the file's directory
cd /Users/kal/Documents/lily/yoga/aquarian-chants/sitar
lilypond raag-yaman-kalyan.ly

# From parent directory
cd /Users/kal/Documents/lily/yoga/aquarian-chants
cd sitar && lilypond raag-yaman-kalyan.ly
```

### Other Useful Commands

```bash
# View generated PDF (macOS)
open raag-yaman-kalyan.pdf

# Clean all PDF outputs
rm *.pdf

# Syntax validation with detailed logging
lilypond --loglevel=DEBUG raag-yaman-kalyan.ly

# Check LilyPond version (should be 2.24.x)
lilypond --version
```

### VSCode Integration

- **Build command:** `Cmd+Shift+B` (uses tasks.json default build task)
- The task runs `lilypond ${fileBasename}` in the file's directory
- Problem matcher configured for English/German error messages

## File Structure

```
sitar/
├── raag.ly              # Core Sargam library (handle with care!)
├── raag-yaman-kalyan.ly # Example composition
├── raad-demo.ly         # Demo file
└── *.pdf                # Generated outputs (git-ignored)

../
└── paper.ily            # Global paper/font configuration
```

**Note:** PDF files are git-ignored by design. Only source `.ly` files are tracked.

## Code Style Guidelines

### Version Declaration

Always start files with a version declaration:

```lilypond
\version "2.24.0"  % Preferred
% OR
\version "2.24"    % Also acceptable
```

Most files use `"2.24.0"`, some older compositions use `"2.18.0"`.

### Include Order

Follow this standard order:

```lilypond
\version "2.24.0"

\include "../paper.ily"
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

**Important:** Use `\language "sargam"` (already set in raag.ly) to enable these pitch names.

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

### Octave Notation

- **Super-dots (above note):** Indicate higher octaves (taar saptak)
- **Sub-dots (below note):** Indicate lower octaves (mandra saptak)
- **Number of dots:** Corresponds to octave displacement from middle register

Example: A note with 2 dots above is two octaves higher than middle register.

### Duration Notation in Sargam Staff

The `sargamHeadStencil` function applies visual indicators based on `duration-log`:

- **dur-log 3** (eighth notes): Underlined note name
- **dur-log 1** (half notes): Single dash postfix (`S-`)
- **dur-log 0** (whole notes): Triple dash postfix (`S---`)
- **dur-log 2** (quarter notes): No special marking (bold text only)

### Special Commands

```lilypond
\chik      % Sitar stroke notation (tick mark above rest)
\tintal    % 16-beat tala cycle (4+4+4+4)
\jhaptal   % 10-beat tala cycle (2+3+2+3)
```

### Custom Contexts

**SargamVoice** (raag.ly:233)

- Voice context with pitch squashing and slash-style note heads
- Hidden stems, consists of Note_heads_engraver and Text_engraver
- Aliased to standard Voice for compatibility

**SargamStaff** (raag.ly:253)

- Staff with no staff lines (`line-count = #0`)
- Custom bar extent for visibility
- Overrides NoteHead.stencil with `sargamHeadStencil`
- Includes all RhythmicStaff engravers plus custom engravers

## Custom Engravers (Brief Documentation)

> For the design history, dead ends, and the *why* behind the current
> implementation, see `EXPERIMENT-LOG.md`.

### Sargam_beam_tie_engraver (raag.ly, defined just before `sargamHeadStencil`)

**Purpose:** Draws the **rhythmic grouping arc** under the Sargam letters.
**One arc = one beat (one quarter note).** The **number of letters under one arc
encodes the subdivision of that beat**:

| notes under one arc | meaning      |
| ------------------- | ------------ |
| 1                   | (no arc — plain quarter note) |
| 2                   | eighth notes |
| 3                   | triplet      |
| 4                   | sixteenths   |

This is **independent of beaming**. In 4/4, `M8 M P P D D` is one 6-note beam but
**three beats**, so it draws **three arcs** (M-M, P-P, D-D). See
`sargam-rhythm.jpeg` for the authoritative rule. (The engraver name is now a
misnomer — it groups by beat, not beam — kept for git history continuity.)

**Status:** Working in single-staff and multi-staff. Triplets and sixteenths
produce arcs but still need visual polish (collisions with the 16th underline /
octave dots).

**How it works:**

1. As each note head is acknowledged, bucket it by the beat it starts in:
   `beat = floor(absoluteMoment / 1/4)` (beat length = quarter note,
   `sargam-beat-length`). Using the **absolute** moment keeps `\partial` pickups
   and compound talas (`\tintal`, `\jhaptal`) correct.
2. At **`finalize`**, every beat bucket with **2+ note heads** gets ONE `Tie`
   grob bound LEFT = first, RIGHT = last note head of that beat.
3. It **anchors the tie's X and Y parent to the left note head**
   (`ly:grob-set-parent!`) and sets explicit **`control-points`**. This bypasses
   LilyPond's automatic tie positioning, which fails in a `line-count = 0`,
   pitch-squashed staff. Without the forced parents/control-points the arc is
   invisible or escapes to another staff.

**Why a Tie and not a Slur:** in this context a manual Slur is invisible (slurs
attach to a `NoteColumn`, which `SargamVoice` does not create), while a Tie
binds to note heads and renders. See `EXPERIMENT-LOG.md`.

**Layout wiring** (already set in `raag.ly`'s `SargamStaff` context):

```lilypond
\consists Tie_engraver            % collects/draws the Tie grobs we create
\consists #Sargam_beam_tie_engraver
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

Always test with a known working file after modifying engravers:

```bash
lilypond raag-yaman-kalyan.ly
open raag-yaman-kalyan.pdf
```

Check for:

- Unexpected note positioning
- Missing voice line connections
- Grob errors in console output
- Visual artifacts in PDF

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

### Layout Overrides

Custom layout modifications are defined in `raag.ly` (the `\layout` block near the end). Use existing patterns as templates:

```lilypond
\layout {
  \context {
    \SargamStaff
    \consists Tie_engraver
    \consists #Sargam_beam_tie_engraver
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
   - Check relative paths: `\include "../paper.ily"`
   - Ensure raag.ly is in the same directory

2. **Pitch name typos**
   - Remember: Sargam uses `S, Re, G, M, P, D, N` (not `c, d, e, f, g, a, b`)
   - Lowercase variants: `re, g, m, d, n` are flats

3. **Bracket/brace mismatches**
   - LilyPond: `{ }` for music, `< >` for chords
   - Scheme: `( )` for all expressions

4. **Grob property errors**
   - Property names are case-sensitive: `NoteHead.stencil` not `notehead.stencil`
   - Use `\override` for grob properties, not direct assignment

### Debug Mode

For verbose output with detailed diagnostics:

```bash
lilypond --loglevel=DEBUG raag-yaman-kalyan.ly
```

---

## Summary for AI Agents

**Primary Task:** When working with this codebase, you are modifying LilyPond music notation files for Indian classical music. The system uses custom Scheme engravers and specialized Sargam notation.

**Key Priorities:**

1. Maintain compatibility with LilyPond 2.24.x
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
