\version "2.26.0"

%% LIBRARY

%% Special commands for Sitar

%% A chikari ("chik") stroke: the open drone/rhythm strings, struck on the beat.
%% Takes a duration: \chik 4 (one beat, the usual case), \chik 8, \chik 16, ...
%%
%% It is a note tagged 'chik, so it counts toward the beat-grouping arc and
%% shows its duration (stem, flag, beam). Normal Staff: a slash head on the
%% middle line, like a guitar strumming pattern. Sargam: the letter "C" (see
%% sargamHeadStencil). The pitch is Sa, which every key contains (no accidental),
%% wrapped in \absolute so it does not shift the \relative reference pitch.
#(set-object-property! 'chik 'music-type? boolean?)
#(set-object-property! 'chik 'music-doc
  "set on a NoteEvent to mark it as a chikari stroke")

chik =
#(define-music-function (dur) (ly:duration?)
   (make-music 'UnrelativableMusic
     'element (make-music 'NoteEvent
                'pitch (ly:make-pitch 0 0 NATURAL)
                'duration dur
                'chik #t
                'tweaks '(((NoteHead . style) . slash)
                          ((NoteHead . staff-position) . 0)))))

%% Bols (mizrab / plectrum strokes) — a stroke-annotation row below the notes.
%% Conceptually like violin bowing or guitar picking, so these work on ANY
%% staff (normal notation Staff and SargamStaff alike), not just Sargam.
%%
%%   \da   = single downstroke, drawn as a vertical bar  |
%%   \ra   = single upstroke,   drawn as a dash          —
%%   \diri = fast down-up across TWO notes, drawn as a caret/triangle ⌃
%%
%% All three bols are drawn by Bol_arc_engraver as note-head-anchored stencils
%% at ONE fixed baseline (sargam-bol-baseline) below the letters, so they share
%% a single row and never collide with the beat-grouping arc. On the pitch-
%% squashed SargamStaff (heads at position 0) this yields a flat row; on a normal
%% Staff the bols track the note heads like ordinary bowing/picking marks.
#(define sargam-bol-baseline -5.2)

%% Single-note bols. Written PREFIX like \diri (\da G, \ra Re): they mutate the
%% note event's 'bol property, the same cross-staff mechanism \diri uses, so they
%% render on BOTH the normal Staff and the SargamStaff. (A postfix G\da cannot
%% reach the normal staff, which strips articulations before the note head is
%% engraved.)
#(set-object-property! 'bol 'music-type? symbol?)
#(set-object-property! 'bol 'music-doc
  "set on a NoteEvent to 'da or 'ra to mark a single-note plectrum stroke")

%% All note events in @var{music}, in order (used by \da, \ra, \diri, \meend).
#(define (sargam-note-events music)
   (filter (lambda (e) (memq 'note-event (ly:music-property e 'types)))
           (extract-named-music music '(NoteEvent))))

#(define (sargam-tag-single-bol music kind)
   (let ((notes (sargam-note-events music)))
     (if (not (= (length notes) 1))
         (ly:error "\\da / \\ra must wrap exactly 1 note, got ~a" (length notes))
         (begin (ly:music-set-property! (car notes) 'bol kind) music))))

da =
#(define-music-function (music) (ly:music?)
   (sargam-tag-single-bol music 'da))
ra =
#(define-music-function (music) (ly:music?)
   (sargam-tag-single-bol music 'ra))

%% \diri wraps EXACTLY two notes (any durations: 16+16, 8+16, 16+8, 8+8, ...)
%% and tags the first note LEFT and the last note RIGHT, so Bol_arc_engraver can
%% draw one arc spanning the pair. Pairing is explicit (from the wrap), NOT
%% inferred from rhythm.
#(set-object-property! 'diri 'music-type? symbol?)
#(set-object-property! 'diri 'music-doc
  "set on a NoteEvent to LEFT/RIGHT to mark a diri stroke pair endpoint")

diri =
#(define-music-function (music) (ly:music?)
   (let ((notes (sargam-note-events music)))
     (if (not (= (length notes) 2))
         (ly:error "\\diri must wrap exactly 2 notes, got ~a" (length notes))
         (begin
           (ly:music-set-property! (car notes) 'diri LEFT)
           (ly:music-set-property! (cadr notes) 'diri RIGHT)
           music))))

%% \meend wraps TWO OR MORE notes played as one continuous glide (one stroke).
%%   Normal Staff: a slur over all notes plus a glissando line between each pair
%%     (added as articulations; SargamVoice has no Slur/Glissando engraver, so
%%     the Sargam side ignores them).
%%   SargamStaff: a flat arc ABOVE the letters with ends hooking down onto the
%%     first and last note (OME Bhatkhande style), drawn by Meend_engraver.
%% A stroke needed inside the meend is written with \da on that note.
#(set-object-property! 'meend 'music-type? symbol?)
#(set-object-property! 'meend 'music-doc
  "set on a NoteEvent to LEFT/RIGHT to mark the first/last note of a meend")

meend =
#(define-music-function (music) (ly:music?)
   (let ((notes (sargam-note-events music)))
     (if (< (length notes) 2)
         (ly:error "\\meend must wrap at least 2 notes, got ~a" (length notes)))
     (let ((add! (lambda (note ev)
                   (ly:music-set-property! note 'articulations
                     (cons ev (ly:music-property note 'articulations))))))
       (ly:music-set-property! (car notes) 'meend LEFT)
       (ly:music-set-property! (last notes) 'meend RIGHT)
       (add! (car notes) (make-music 'SlurEvent 'span-direction START))
       (add! (last notes) (make-music 'SlurEvent 'span-direction STOP))
       (for-each (lambda (n) (add! n (make-music 'GlissandoEvent)))
                 (drop-right notes 1))
       music)))

%% Indian Rhythms
jhaptal =  \time #'((2) (3) (2) (3)) 10/4  
tintal = \time #'((4) (4) (4) (4)) 16/4 
jattaal = \time #'((4) (4) ) 8/4 

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
%% We can now select "sargam" as the language to get these pitch names in the score.
%% But this is a user choice because the same pitch names are used in different contexts
%% \language "sargam"

#(define-syntax-rule (log-exprs exp ...)
  (begin (format #t "~a: ~S\n" (quote exp) exp) ...))

#(define (swap-pair p)
   (cons (cdr p) (car p)))
pitchToSargam = #(map swap-pair sargamPitchNames)

%% Sargam letters are relative to Sa (the tonic), NOT to absolute pitch, and are
%% computed CHROMATICALLY (by semitone from Sa) so they survive any \transpose
%% and enharmonic respelling. By default Sa = C. If a staff is transposed (e.g.
%% \transpose S Re moves the sounding key up a tone), set \sargamSa to the ACTUAL
%% sounding pitch of Sa so the letters and octave dots stay Sa-relative:
%%
%%   \new SargamVoice { \sargamSa Re \transpose S Re { \melody } }
%%
%% \sargamSa sets the NoteHead.sargam-sa grob property; the head stencil reads it.
#(define sargam-sa-default (ly:make-pitch -1 0 NATURAL))

#(set-object-property! 'sargam-sa 'backend-type? ly:pitch?)
#(set-object-property! 'sargam-sa 'backend-doc
  "the sounding pitch of Sa for this staff (sargam letters are relative to it)")
#(if (not (memq 'sargam-sa all-user-grob-properties))
     (set! all-user-grob-properties (cons 'sargam-sa all-user-grob-properties)))

sargamSa =
#(define-music-function (p) (ly:pitch?)
   #{ \override NoteHead.sargam-sa = #p #})

%% Semitone distance from Sa -> sargam letter. This is transposition-invariant
%% (chromatic), so it is robust to whatever enharmonic spelling \transpose picks.
%% Bhatkhande case convention: shuddha (natural) swaras are CAPITAL, komal (flat)
%% swaras are lowercase. Both Ma variants print as capital "M"; tivra Ma (6) is
%% additionally barred (handled in the stencil).
%% 0=S 1=r 2=R 3=g 4=G 5=M(shuddha) 6=M(tivra,barred) 7=P 8=d 9=D 10=n 11=N.
#(define sargam-semitone-strings
   #("S" "r" "R" "g" "G" "M" "M" "P" "d" "D" "n" "N"))

%% Chromatic semitone of a pitch measured from Sa=C (octave folded out).
#(define (sargam-chromatic p)
   (+ (list-ref '(0 2 4 5 7 9 11) (ly:pitch-notename p))
      (inexact->exact (round (* 2 (ly:pitch-alteration p))))))

#(define (sargam-semitone-from-sa pitch sa)
   (modulo (- (sargam-chromatic pitch) (sargam-chromatic sa)) 12))

%% Register (saptak) of @var{pitch} relative to Sa: 0 = middle, +1 = upper, etc.
%% Uses absolute chromatic so it is correct under any \transpose spelling. Sa is
%% folded to the middle octave (0) so that a note in Sa's own octave reads as
%% middle regardless of how Sa itself is spelled.
#(define (sargam-register pitch sa)
   (let* ((abs-p (+ (* 12 (ly:pitch-octave pitch)) (sargam-chromatic pitch)))
          (sa-chroma (sargam-chromatic sa))
          ;; Sa placed in the same octave as the note's octave-0 frame
          (abs-sa sa-chroma))
     (floor (/ (- abs-p abs-sa) 12))))

%% The sargam letter string for @var{pitch} relative to @var{sa}, e.g. "M" for
%% tivra Ma. Returns the bare letter; the barred-M substitution happens in the
%% stencil (only the tivra-Ma semitone, 6, is the barred capital M).
#(define (sargam-letter pitch sa)
   (vector-ref sargam-semitone-strings (sargam-semitone-from-sa pitch sa)))

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

%% One octave dot as a stencil (a small filled circle; font-independent).
#(define (sargam-dot-stencil radius)
   (make-circle-stencil radius 0 #t))

%% Build a note-head stencil: the letter with @var{super} octave dots above and
%% @var{sub} octave dots below. The LETTER is the anchor: it always sits on the
%% same baseline regardless of octave, and the dots are placed at a small fixed
%% gap from the letter's actual top/bottom extent (so a taar dot lands ABOVE the
%% tivra-Ma bar, choice A). Dots are horizontally centred on the letter and
%% stack outward for ati-taar / ati-mandra (2+ octaves).
%% gap between letter and first dot; vertical step between stacked dots
#(define sargam-dot-gap 0.45)
#(define sargam-dot-step 0.6)
#(define sargam-dot-radius 0.14)

#(define (sargam-stack-note note-stc super sub)
   (let* ((dot (sargam-dot-stencil sargam-dot-radius))
          (xe (ly:stencil-extent note-stc X))
          (ye (ly:stencil-extent note-stc Y))
          (cx (/ (+ (car xe) (cdr xe)) 2))
          ;; a single dot centred at (cx . y)
          (place-dot (lambda (y) (ly:stencil-translate dot (cons cx y))))
          (result note-stc))
     ;; super dots: above the letter's top, stacking upward
     (let loop ((i 0) (y (+ (cdr ye) sargam-dot-gap)))
       (when (< i super)
         (set! result (ly:stencil-add result (place-dot y)))
         (loop (+ i 1) (+ y sargam-dot-step))))
     ;; sub dots: below the letter's bottom, stacking downward
     (let loop ((i 0) (y (- (car ye) sargam-dot-gap)))
       (when (< i sub)
         (set! result (ly:stencil-add result (place-dot y)))
         (loop (+ i 1) (- y sargam-dot-step))))
     result))

%% Borrowd from Lily 2.25.1
#(define (ly:event-length event moment)
  (ly:event-property event 'length))



%%% RHYTHMIC GROUPING ARC
%%%
%%% In Sargam notation a curved arc UNDER the note letters marks ONE BEAT
%%% (= one quarter note). The number of events that fall in that beat shows how
%%% the beat is subdivided:
%%%   1 event  = a plain quarter note (NO arc is drawn)
%%%   2 events = eighth notes
%%%   3 events = triplet
%%%   4 events = sixteenth notes, etc.
%%% Events are grouped by the beat they start in; an arc is drawn for every beat
%%% that holds 2+ events. Rests count as events (a held/empty subdivision), so a
%%% beat of `S8 r8` is arced. See sargam-rhythm.jpeg for the authoritative rule.
%%%
%%% This is purely about musical TIME (beats), NOT about how LilyPond beams the
%%% notes. The same notes might be drawn under one beam or several, or no beam
%%% at all (auto-beaming), and the arcs are unaffected: e.g. in 4/4 the six
%%% eighths `M8 M P P D D` are one beam but THREE beats, so they get THREE arcs.
%%%
%%% WHY a Tie grob with FORCED control-points (see EXPERIMENT-LOG.md):
%%% The SargamStaff has StaffSymbol.line-count = 0 and pitch-squashed note
%%% heads, which leaves LilyPond's automatic Tie/Slur vertical positioning
%%% (Staff_symbol_referencer) without a valid Y reference, so an auto-placed
%%% arc collapses to invisible. Setting explicit `control-points` bypasses
%%% that calculation entirely and renders reliably. The control points are
%%% computed lazily (as a grob callback) once horizontal positions are known.

%% Build the four Bezier control points for the grouping arc that spans from
%% @var{left-nh} to @var{right-nh} (each may be a note head OR a rest).
%% Coordinates are returned relative to the tie's own origin so they are
%% independent of where the grob is parented.
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
%% number of events (note heads and/or rests) under it shows the subdivision of
%% that beat (2 = eighths, 3 = triplet, 4 = sixteenths, ...). A beat with a
%% single event gets no arc. This follows the Sargam rhythmic notation
%% (sargam-rhythm.jpeg) and is independent of how LilyPond beams the notes.
#(define sargam-beat-length 1/4)

%% Which beat does musical moment @var{m} (a rational) fall in?
#(define (sargam-beat-index m)
   (inexact->exact (floor (/ m sargam-beat-length))))

#(define (Sargam_beat_arc_engraver context)
   "Draws one grouping arc per BEAT (quarter note). Note heads AND rests are
    bucketed by the beat they start in; any beat containing two or more events
    gets a single arc spanning its first..last event. Rests count as members of
    the beat (a beat of `S8 r8` is two subdivisions, so it is arced), matching
    the Sargam rhythmic notation. The arc is NOT a copy of LilyPond's beaming."
   ;; Association list: beat-index -> list of grobs (note heads or rests).
   (let ((by-beat '()))
     ;; File @var{grob} into the bucket for the beat it starts in.
     (define (bucket! grob)
       (let* ((beat (sargam-beat-index
                      (ly:moment-main (ly:context-current-moment context))))
              (entry (assv beat by-beat)))
         (if entry
             (set-cdr! entry (cons grob (cdr entry)))
             (set! by-beat (cons (list beat grob) by-beat)))))
     (make-engraver
      (acknowledgers
       ;; A note head OR a rest occupies a subdivision of its beat.
       ((note-head-interface engraver grob source-engraver)
        (bucket! grob))
       ((rest-interface engraver grob source-engraver)
        (bucket! grob)))

      ((finalize engraver)
       (for-each
        (lambda (entry)
          (let ((members (reverse (cdr entry))))   ; chronological order
            (when (>= (length members) 2)
              (let* ((left (car members))
                     (right (car (last-pair members)))
                     (tie (ly:engraver-make-grob engraver 'Tie left)))
                (ly:spanner-set-bound! tie LEFT left)
                (ly:spanner-set-bound! tie RIGHT right)
                ;; Anchor the arc's Y (and X) coordinate system on the left
                ;; member, so the forced control points are interpreted
                ;; relative to the Sargam letters in EVERY context (single-
                ;; and multi-staff). Without this the arc inherits an
                ;; ambiguous Y reference in multi-staff scores and renders
                ;; far away / off the staff.
                (ly:grob-set-parent! tie Y left)
                (ly:grob-set-parent! tie X left)
                (ly:grob-set-property! tie 'direction DOWN)
                ;; Forced control points -> bypass broken auto positioning.
                (ly:grob-set-property! tie 'control-points
                  (sargam-arc-control-points left right))
                (ly:engraver-announce-end-grob engraver tie right)))))
        by-beat)
       (set! by-beat '()))
       )))

%% Build a triangle (caret ⌃) stencil for the diri bol, spanning from
%% @var{left-nh} to @var{right-nh}, drawn on the bol row BELOW the letters.
%% This is the book's diri glyph (like \rtoe), not a bow. Coordinates are
%% relative to the grob's own origin (parented to the left note head).
#(define ((sargam-bol-triangle-stencil left-nh right-nh) grob)
   (let* ((refp (ly:grob-common-refpoint left-nh right-nh X))
          (lx (ly:grob-relative-coordinate left-nh refp X))
          (rx (ly:grob-relative-coordinate right-nh refp X))
          (lext (ly:grob-property left-nh 'X-extent))
          (rext (ly:grob-property right-nh 'X-extent))
          (x0 (+ lx (if (pair? lext) (* 0.5 (car lext)) 0)))
          (x1 (+ rx (if (pair? rext) (* 0.5 (cdr rext)) 0)))
          (self-x (ly:grob-relative-coordinate grob refp X))
          (a (- x0 self-x))
          (b (- x1 self-x))
          (mid (/ (+ a b) 2))
          (base (sargam-bol-base grob))   ; bol row baseline (feet of the triangle)
          (apex (+ base 0.9))   ; peak of the caret
          (th 0.12))    ; line thickness
     (ly:stencil-add
       (make-line-stencil th a base mid apex)
       (make-line-stencil th mid apex b base))))

%% The bol baseline expressed in @var{grob}'s OWN Y frame, such that in STAFF
%% coordinates it always equals sargam-bol-baseline. This keeps the bol row flat
%% relative to the staff (not the note head): on the pitch-squashed SargamStaff
%% heads sit at position 0 anyway, while on a normal Staff this cancels the
%% head's pitch so the bols form one flat row below the staff instead of drifting
%% with the melody.
#(define (sargam-bol-base grob)
   (let ((staff (ly:grob-object grob 'staff-symbol)))
     (if (ly:grob? staff)
         (let* ((refp (ly:grob-common-refpoint grob staff Y))
                (grob-y (ly:grob-relative-coordinate grob refp Y))
                (staff-y (ly:grob-relative-coordinate staff refp Y)))
           ;; bol baseline (staff-relative) expressed in the grob's own Y frame
           (- (+ staff-y sargam-bol-baseline) grob-y))
         sargam-bol-baseline)))

#(define (sargam-bol-kind note-event)
   (if (ly:stream-event? note-event)
       (ly:event-property note-event 'bol #f)
       #f))

%% Stencil for a single-note bol (da = vertical bar, ra = dash), drawn centered
%% on @var{nh} at the shared bol baseline. Coordinates are relative to the
%% grob's own origin (parented to the note head).
#(define ((sargam-bol-mark-stencil nh kind) grob)
   (let* ((self-x (ly:grob-relative-coordinate grob nh X))
          (ext (ly:grob-property nh 'X-extent))
          ;; note-head visual center in the grob's own X frame
          (cx (+ (- 0 self-x)
                 (if (pair? ext) (* 0.5 (+ (car ext) (cdr ext))) 0)))
          (base (sargam-bol-base grob))
          (th 0.22))
     (case kind
       ;; da: a vertical downstroke bar |
       ((da) (make-line-stencil th cx base cx (+ base 1.6)))
       ;; ra: a horizontal upstroke dash —
       ((ra) (make-line-stencil th (- cx 0.8) (+ base 0.7) (+ cx 0.8) (+ base 0.7)))
       (else empty-stencil))))

%% Draws the diri caret (⌃, a triangle) across each pair of note heads tagged
%% by \diri, AND the single-note bols \da (|) and \ra (—). All three sit on the
%% shared bol baseline (sargam-bol-baseline) below the letters. Pairs are
%% explicit (from the \diri wrap). We reuse a Tie spanner ONLY as a positioning
%% vehicle (forced parent-anchoring to a note head so it renders on both a normal
%% Staff and the pitch-squashed SargamStaff), overriding its stencil.
#(define (Bol_arc_engraver context)
   "Draws diri carets and \\da/\\ra single-note bols on the shared bol row."
   (let ((pending-left #f))
     (make-engraver
      (acknowledgers
       ((note-head-interface engraver grob source-engraver)
        ;; Single-note bol (\da / \ra): a mark centered on this head.
        (let ((kind (sargam-bol-kind (event-cause grob))))
          (when (symbol? kind)
            (let ((mark (ly:engraver-make-grob engraver 'Tie grob)))
              (ly:spanner-set-bound! mark LEFT grob)
              (ly:spanner-set-bound! mark RIGHT grob)
              (ly:grob-set-parent! mark Y grob)
              (ly:grob-set-parent! mark X grob)
              (ly:grob-set-property! mark 'stencil
                (sargam-bol-mark-stencil grob kind))
              (ly:engraver-announce-end-grob engraver mark grob))))
        ;; Diri caret: spans a tagged pair.
        (let ((tag (ly:event-property (event-cause grob) 'diri #f)))
          (cond
           ((eqv? tag LEFT) (set! pending-left grob))
           ((and (eqv? tag RIGHT) pending-left)
            (let* ((left pending-left)
                   (right grob)
                   (tie (ly:engraver-make-grob engraver 'Tie left)))
              (ly:spanner-set-bound! tie LEFT left)
              (ly:spanner-set-bound! tie RIGHT right)
              (ly:grob-set-parent! tie Y left)
              (ly:grob-set-parent! tie X left)
              (ly:grob-set-property! tie 'stencil
                (sargam-bol-triangle-stencil left right))
              (ly:engraver-announce-end-grob engraver tie right)
              (set! pending-left #f))))))))))

%% Meend arc (OME Bhatkhande style): a flat line ABOVE the letters from the
%% first to the last note of the meend, its ends hooking down onto those two
%% letters. The line sits a fixed gap above the TALLEST member (letter plus
%% octave dots), so it stays flat and never hits a taar dot.
#(define sargam-meend-gap 0.4)    % clearance above the tallest member
#(define sargam-meend-hook 0.7)   % how far the ends hook down

#(define ((sargam-meend-stencil members) grob)
   (let* ((left (car members))
          (right (last members))
          (refx (ly:grob-common-refpoint left right X))
          (self-x (ly:grob-relative-coordinate grob refx X))
          (a (+ (- (ly:grob-relative-coordinate left refx X) self-x)
                (car (ly:grob-extent left left X))))
          (b (+ (- (ly:grob-relative-coordinate right refx X) self-x)
                (cdr (ly:grob-extent right right X))))
          ;; tallest member top, in the grob's own Y frame
          (top (apply max
                 (map (lambda (m)
                        (let ((refy (ly:grob-common-refpoint grob m Y)))
                          (- (+ (ly:grob-relative-coordinate m refy Y)
                                (cdr (ly:grob-extent m m Y)))
                             (ly:grob-relative-coordinate grob refy Y))))
                      members)))
          (h (+ top sargam-meend-gap sargam-meend-hook))
          (r (min 1.2 (/ (- b a) 3))))   ; corner radius
     (make-path-stencil
       `(moveto ,a ,(- h sargam-meend-hook)
         curveto ,a ,(- h 0.15) ,(+ a (* 0.3 r)) ,h ,(+ a r) ,h
         lineto ,(- b r) ,h
         curveto ,(- b (* 0.3 r)) ,h ,b ,(- h 0.15) ,b ,(- h sargam-meend-hook))
       0.18 1 1 #f)))

%% Collects the note heads of each \meend (tagged LEFT ... RIGHT) and draws one
%% arc over them. Like the bols, a Tie spanner is used only as a positioning
%% vehicle, parent-anchored to the first note head, with its stencil replaced.
#(define (Meend_engraver context)
   "Draws a meend arc above the letters of each \\meend."
   (let ((members '()))   ; note heads of the open meend, newest first
     (make-engraver
      (acknowledgers
       ((note-head-interface engraver grob source-engraver)
        (let ((tag (ly:event-property (event-cause grob) 'meend #f)))
          (cond
           ((eqv? tag LEFT) (set! members (list grob)))
           ((pair? members)
            (set! members (cons grob members))
            (when (eqv? tag RIGHT)
              (let* ((heads (reverse members))
                     (left (car heads))
                     (arc (ly:engraver-make-grob engraver 'Tie left)))
                (ly:spanner-set-bound! arc LEFT left)
                (ly:spanner-set-bound! arc RIGHT grob)
                (ly:grob-set-parent! arc Y left)
                (ly:grob-set-parent! arc X left)
                (ly:grob-set-property! arc 'stencil
                  (sargam-meend-stencil heads))
                (ly:engraver-announce-end-grob engraver arc grob)
                (set! members '())))))))))))

%% How many trailing beats does a note of @var{dur-log} (whole=0, half=1)
%% occupy beyond its first beat, ignoring dots? Falls back to dur-log when the
%% real duration is unavailable.
#(define (sargam-extra-beats dur length)
   ;; @var{length} is the note's full duration as a moment-main rational, or #f.
   (cond
    ((and length (> length 0))
     (max 0 (- (inexact->exact (round (/ length sargam-beat-length))) 1)))
    ((eqv? dur 0) 3)   ; whole note  -> 4 beats
    ((eqv? dur 1) 1)   ; half note   -> 2 beats
    (else 0)))

%% A note that lasts longer than one beat is written as the letter followed by
%% one em-dash per extra beat (S — for a half note, S — — for a dotted half,
%% S — — — for a whole note), with a little space before the first dash.
#(define (sargam-duration-postfix-markup n-dashes)
   (if (<= n-dashes 0)
       (markup "")
       (make-line-markup
         (cons (make-hspace-markup 0.4)
               (map (lambda (i) (markup "–")) (iota n-dashes))))))

%% Tivra Ma is written in Bhatkhande notation as a capital "M" with a short
%% vertical bar centered ON TOP of the letter (shuddha Ma is a plain capital M).
%% We measure the M's actual extent and place the bar at its horizontal centre,
%% just above its top, keeping the M on the baseline. No special font is needed
%% and only tivra Ma is affected.
#(define-markup-command (sargamBarredM layout props) ()
   (let* ((m (interpret-markup layout props (markup #:bold "M")))
          (xe (ly:stencil-extent m X))
          (ye (ly:stencil-extent m Y))
          (cx (/ (+ (car xe) (cdr xe)) 2))
          (top (cdr ye))
          (bar (make-line-stencil 0.22 cx (+ top 0.15) cx (+ top 0.75))))
     (ly:stencil-add m bar)))

#(define (sargamHeadStencil grob)
   (let* (
          (shape (ly:grob-property grob 'style))
          (dur-log (ly:grob-property grob 'duration-log))
          (cause (event-cause grob))
          (raw-pitch (ly:event-property cause 'pitch))
          ;; chikari stroke (\chik): letter "C", no octave dots
          (chik? (ly:event-property cause 'chik #f))
          ;; Sa reference for this staff (default C); makes the letter Sa-relative
          ;; so it survives \transpose. Set via \sargamSa.
          (sa (let ((v (ly:grob-property grob 'sargam-sa #f)))
                (if (ly:pitch? v) v sargam-sa-default)))
          ;; register (saptak) dots relative to Sa: 0 = middle (no dots).
          (octave (if chik? 0 (sargam-register raw-pitch sa)))
          (semitone (sargam-semitone-from-sa raw-pitch sa))
          (head0 (if chik? "C" (sargam-letter raw-pitch sa)))
          ;; tivra Ma (6 semitones above Sa) -> barred capital M (Bhatkhande)
          (head (if (= semitone 6) (markup #:sargamBarredM) head0))
          (note-dur (ly:event-property cause 'duration))
          (note-length (if (ly:duration? note-dur)
                           (ly:moment-main (ly:duration->moment note-dur))
                           #f))
          (n-dashes (sargam-extra-beats dur-log note-length))
          (postfix (sargam-duration-postfix-markup n-dashes))
          (sub (case dur-log
                  ((3) (lambda (m) (make-underline-markup m)))
                  (else (lambda (m) m))))
          ;; octave dot counts: taar (>0) above, mandra (<0) below the letter.
          (n-super (if (> octave 0) octave 0))
          (n-sub   (if (< octave 0) (- octave) 0))
          (note-number
            ;; letter (with octave underline for 8ths) then the em-dash tail
            (make-bold-markup
              (make-line-markup
                (list (sub head) postfix))))
          )
     (grob-interpret-markup grob
          (make-lower-markup 0.5
             (markup #:stencil
               (sargam-stack-note
                 (grob-interpret-markup grob note-number)
                 n-super n-sub)))
          )))


%% A rest in Sargam notation is written as a dash (—), per the rhythmic
%% notation rules. It sits in the same baseline as the note letters and, like a
%% note, counts as one subdivision of its beat (so it can sit under a grouping
%% arc). We render an en-dash in the same bold style as the letters.
#(define (sargamRestStencil grob)
   (grob-interpret-markup grob
     (make-lower-markup 0.5
       (make-bold-markup "–"))))


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
    %% Bols work on any staff (like bowing/picking), so consist the diri arc
    %% engraver here too. Tie_engraver is present in Staff by default.
    \consists #Bol_arc_engraver
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
    %% Rests are drawn as a dash (—) in Sargam notation.
    \override Rest.stencil =  #(lambda (grob) (sargamRestStencil grob))

    %% all RhythmicStaff Engraver
    \consists Axis_group_engraver
    \consists Bar_engraver
    \consists Caesura_engraver
    \consists Font_size_engraver
    \consists Instrument_name_engraver
    \consists Ledger_line_engraver
    \consists Apply_output_engraver
    \consists Pitch_squash_engraver
    \consists Separating_line_group_engraver
    \consists Staff_highlight_engraver
    \consists Staff_symbol_engraver
    \consists Time_signature_engraver
    \consists Rest_engraver
    \consists Beam_engraver
    \consists Auto_beam_engraver

    %% Rhythmic grouping arcs: ONE arc per beat (quarter note); notes and rests
    %% in the same beat sit under one arc. Tie_engraver is needed so the 'Tie
    %% grobs we create are collected and drawn.
    \consists Tie_engraver
    \consists #Sargam_beat_arc_engraver
    \consists #Bol_arc_engraver
    \consists #Meend_engraver

    \alias RhythmicStaff
    %% Catch Staff-level settings like \submeasureBarsOn (= \set Staff.…),
    %% as LilyPond's own RhythmicStaff does.
    \alias Staff
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


%{
convert-ly (GNU LilyPond) 2.26.0  convert-ly: Processing `'...
Applying conversion: 2.24.0, 2.25.0, 2.25.1, 2.25.2, 2.25.3, 2.25.4,
2.25.5, 2.25.6, 2.25.8, 2.25.9, 2.25.11, 2.25.12, 2.25.13, 2.25.18,
2.25.22, 2.25.23, 2.25.24, 2.25.25, 2.25.26, 2.25.28, 2.25.30,
2.25.31, 2.25.32, 2.25.33, 2.25.34, 2.25.35, 2.25.80, 2.26.0
%}
