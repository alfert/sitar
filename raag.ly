\version "2.24"

%% LIBRARY

%% Special commands for Sitar
chik = { r4^\markup{\center-align\musicglyph #"scripts.tickmark"} }
% chik = { \arpeggioArrowDown r4\arpeggio \arpeggioNormal}

%% Indian Rhythms
jhaptal = \compoundMeter #'((2 3 2 3 4))
tintal = \compoundMeter #'((4 4 4 4 4))

%%%%%%%%%%%%%%%%%%%%

%% SARGAM Notation auf C-Dur
sargamPitchNames = #`(
  (S . ,(ly:make-pitch -1 0 NATURAL))
  (Re . ,(ly:make-pitch -1 1 NATURAL))
  (re . ,(ly:make-pitch -1 1 FLAT))
  (G . ,(ly:make-pitch -1 2 NATURAL))
  (g . ,(ly:make-pitch -1 2 FLAT))
  (m . ,(ly:make-pitch -1 3 NATURAL))
  (M . ,(ly:make-pitch -1 3 SHARP))
  (P . ,(ly:make-pitch -1 4 NATURAL))
  (D . ,(ly:make-pitch -1 5 NATURAL))
  (d . ,(ly:make-pitch -1 5 FLAT))
  (N . ,(ly:make-pitch -1 6 NATURAL))
  (n . ,(ly:make-pitch -1 6 FLAT))
)
sargamPitchStrings = #`(
  (S . "S")
  (Re . "R")
  (re . "r")
  (G . "G")
  (g . "g")
  (m . "m")
  (M . "M")
  (P . "P")
  (D . "D")
  (d . "d")
  (N . "N")
  (n . "n")
)
%% set pitch names.
#(set! language-pitch-names
       (append language-pitch-names
               (list `(sargam . ,sargamPitchNames))))
\language "sargam"

#(define-syntax-rule (log-exprs exp ...)
  (begin (format #t "~a: ~S\n" (quote exp) exp) ...))

#(define (swap-pair p)
   (cons (cdr p) (car p)))
pitchToSargam = #(map swap-pair sargamPitchNames)

head-name-from-pitch = #(define-scheme-function (pitch) (ly:pitch?)
   (let* (
          (pi (ly:make-pitch -1 (ly:pitch-notename pitch) (ly:pitch-alteration pitch)))
          (p (assoc pi pitchToSargam)))
     (begin
      ;(log-exprs pitch)
      ;(log-exprs pi)
       (if p
           (assoc-ref sargamPitchStrings (cdr p))
           "not found"))))

#(define (stack-dots n)
  "stacks @var{n} dots either below or on top"
  (let* (
          (dot #{ \markup { \override #'(baseline-skip . 0.4) \musicglyph #"dots.dot" } #}))
     (make-column-markup (make-list n dot))
  ))
% #(define (stack-note note super-dots sub-dots)
stack-note = #(define-scheme-function (notename super-dots sub-dots) (markup? markup? markup?)
   "stacks together a single @var(note) with its ocatve dots @var{super-dots}
    and @var{sub-dots}"
    #{  \markup \column { {\raise #-2 #super-dots } #notename {\raise #2 #sub-dots } } #}
   )

%% Borrowd from Lily 2.25.1
#(define (ly:event-length event moment)
  (ly:event-property event 'length))



%%% RHYTHMIC GROUPING ARC
%%%
%%% In Sargam notation a curved arc UNDER a group of note letters encodes the
%%% rhythmic subdivision (it replaces the Western beam):
%%%   2 notes under one arc = eighth notes
%%%   3 notes under one arc = triplet
%%%   4 notes under one arc = sixteenth notes, etc.
%%% So we draw exactly ONE arc per beamed group, spanning the whole group.
%%%
%%% WHY a Tie grob with FORCED control-points (see EXPERIMENT-LOG.md):
%%% The SargamStaff has StaffSymbol.line-count = 0 and pitch-squashed note
%%% heads, which leaves LilyPond's automatic Tie/Slur vertical positioning
%%% (Staff_symbol_referencer) without a valid Y reference, so an auto-placed
%%% arc collapses to invisible. Setting explicit `control-points` bypasses
%%% that calculation entirely and renders reliably. The control points are
%%% computed lazily (as a grob callback) once horizontal positions are known.

%% Build the four Bezier control points for the grouping arc that spans from
%% @var{left-nh} to @var{right-nh}. Coordinates are returned relative to the
%% tie's own origin so they are independent of where the grob is parented.
#(define ((sargam-arc-control-points left-nh right-nh) grob)
   (let* ((refp (ly:grob-common-refpoint left-nh right-nh X))
          (lx (ly:grob-relative-coordinate left-nh refp X))
          (rx (ly:grob-relative-coordinate right-nh refp X))
          (lext (ly:grob-property left-nh 'X-extent))
          (rext (ly:grob-property right-nh 'X-extent))
          ;; span just inside the outer edges of the first and last letters
          (x0 (+ lx (if (pair? lext) (* 0.5 (car lext)) 0)))
          (x1 (+ rx (if (pair? rext) (* 0.5 (cdr rext)) 0)))
          (self-x (ly:grob-relative-coordinate grob refp X))
          (a (- x0 self-x))
          (b (- x1 self-x))
          (span (- b a))
          (top -2.2)    ; arc endpoints: depth just below the letters
          (dip -2.9))   ; arc middle: lowest point
     (list (cons a top)
           (cons (+ a (* span 0.25)) dip)
           (cons (+ a (* span 0.75)) dip)
           (cons b top))))

%% One beat = one quarter note. The grouping arc spans exactly one beat; the
%% number of note heads under it shows the subdivision of that beat
%% (2 = eighths, 3 = triplet, 4 = sixteenths, ...). A beat with a single note
%% gets no arc. This follows the Sargam rhythmic notation (sargam-rhythm.jpeg)
%% and is independent of how LilyPond happens to beam the notes.
#(define sargam-beat-length 1/4)

%% Which beat does musical moment @var{m} (a rational) fall in?
#(define (sargam-beat-index m)
   (inexact->exact (floor (/ m sargam-beat-length))))

#(define (Sargam_beam_tie_engraver context)
   "Draws one grouping arc per BEAT (quarter note). Note heads are bucketed by
    the beat they start in; any beat containing two or more note heads gets a
    single arc spanning its first..last note head. The arc is the Sargam
    equivalent of subdivision marks, NOT a copy of LilyPond's beaming."
   ;; Association list: beat-index -> list of note heads (in encounter order).
   (let ((by-beat '()))
     (make-engraver
      (acknowledgers
       ((note-head-interface engraver grob source-engraver)
        ;; Bucket each note head by the beat in which it starts. Rests have no
        ;; note head, so they naturally break a beat's group (and a new beat
        ;; bucket starts after them).
        (let* ((now (ly:moment-main (ly:context-current-moment context)))
               (beat (sargam-beat-index now))
               (entry (assv beat by-beat)))
          (if entry
              (set-cdr! entry (cons grob (cdr entry)))
              (set! by-beat (cons (list beat grob) by-beat))))))

      ((finalize engraver)
       (for-each
        (lambda (entry)
          (let ((heads (reverse (cdr entry))))   ; chronological order
            (when (>= (length heads) 2)
              (let* ((left-nh (car heads))
                     (right-nh (car (last-pair heads)))
                     (tie (ly:engraver-make-grob engraver 'Tie left-nh)))
                (ly:spanner-set-bound! tie LEFT left-nh)
                (ly:spanner-set-bound! tie RIGHT right-nh)
                ;; Anchor the arc's Y (and X) coordinate system on the left
                ;; note head, so the forced control points are interpreted
                ;; relative to the Sargam letters in EVERY context (single-
                ;; and multi-staff). Without this the arc inherits an
                ;; ambiguous Y reference in multi-staff scores and renders
                ;; far away / off the staff.
                (ly:grob-set-parent! tie Y left-nh)
                (ly:grob-set-parent! tie X left-nh)
                (ly:grob-set-property! tie 'direction DOWN)
                ;; Forced control points -> bypass broken auto positioning.
                (ly:grob-set-property! tie 'control-points
                  (sargam-arc-control-points left-nh right-nh))
                (ly:engraver-announce-end-grob engraver tie right-nh)))))
        by-beat)
       (set! by-beat '()))
       )))

#(define (sargamHeadStencil grob)
   (let* (
          (shape (ly:grob-property grob 'style))
          (dur-log (ly:grob-property grob 'duration-log))
          (pitch (ly:event-property (event-cause grob) 'pitch))
          (octave (ly:pitch-octave pitch))
          (head (head-name-from-pitch pitch))
          (postfix (case dur-log
                      ((0) "---")
                      ((1) "-")
                      (else "")))
          (sub (case dur-log
                  ((3) (lambda (m) (make-underline-markup m)))
                  (else (lambda (m) m))))
          ;; Punkte drüber/drunter für die Oktaven!
          (super-dots
            (if (> octave 0)
              (stack-dots octave)
              (markup "")
              ))
         (sub-dots (if (< octave 0)
              (stack-dots (- octave))
              (markup "")))
         (note-number
          (begin
           ;(log-exprs head)
            (make-bold-markup (sub (string-append head postfix))))
          )
          )
     (grob-interpret-markup grob
          (make-lower-markup 0.5
             (stack-note  note-number super-dots sub-dots)
          ))))


\layout {
  \context {
    \name SargamVoice
    \type Engraver_group
    \consists Note_heads_engraver
    \consists Stem_engraver
    \consists Text_engraver
    \consists Pitch_squash_engraver
    \consists Beam_engraver
    squashedPosition = #0
    %\override NoteHead.style = #'slash
    \override NoteHead.stencil =  #(lambda (grob) (sargamHeadStencil grob))

    \hide Stem
    \alias Voice
  }
  
  \context {
    \Staff
    \accepts SargamVoice
  }
  \context {
    \name SargamStaff
    \type Engraver_group
    %\consists Accidental_engraver
    \override StaffSymbol.line-count = #0
    \override BarLine.bar-extent = #'(-2 . 2)
    \override Stem.transparent = ##t

    \accepts Voice
    \accepts SargamVoice
    \override NoteHead.stencil =  #(lambda (grob) (sargamHeadStencil grob))

    %% all RhythmicStaff Engraver
    \consists Axis_group_engraver
    \consists Bar_engraver
    \consists Caesura_engraver
    \consists Font_size_engraver
    \consists Instrument_name_engraver
    \consists Ledger_line_engraver
    \consists Output_property_engraver
    \consists Pitch_squash_engraver
    \consists Separating_line_group_engraver
    \consists Staff_highlight_engraver
    \consists Staff_symbol_engraver
    \consists Time_signature_engraver
    \consists Rest_engraver
    \consists Beam_engraver
    \consists Auto_beam_engraver

    %% Rhythmic grouping arcs below beamed note groups.
    %% Tie_engraver is needed so the 'Tie grobs we create are collected
    %% and drawn; Sargam_beam_tie_engraver supplies one arc per beam group.
    \consists Tie_engraver
    \consists #Sargam_beam_tie_engraver

    \alias RhythmicStaff
  }
  \context {
    \SargamStaff
    \accepts SargamVoice
  }
  \context {
    \Score
    \accepts SargamStaff
  }
}
