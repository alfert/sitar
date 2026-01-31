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



%%% 
%%% Beaming könnte über die Markup-Kommandos \tie gehen,
%%% Ebenso Slides / Pulloffs mit \overtie
%%% Auch dieser Ansatz könnte eine Vorlage sein, weil Noten automatisch
%%% miteinander verbunden werden (durch Linien, hier wären es die Ties)
%%% https://extending-lilypond.gitlab.io/en/extending/translation.html#example-for-killing-grobs-voice-line-engraver

#(define (Sargam_beam_tie_engraver context)
   "Creates ties below beamed eighth notes in Sargam notation"
   (let* (
          ;; Current timestep's note head
          (current-note-head #f)
          ;; Store all eighth note heads in current BEAM (across timesteps)
          (beam-eighth-notes '())
          ;; Track if we're inside a beam
          (beam-active #f))
     (make-engraver
      (acknowledgers
       ;; Acknowledge all note heads
       ((note-head-interface engraver grob source-engraver)
        (let* ((cause (ly:grob-property grob 'cause))
               (event-dur-log (if (ly:stream-event? cause)
                                  (ly:duration-log (ly:event-property cause 'duration))
                                  #f)))
          ;; Check if this is an eighth note (event dur-log = 3)
          (when (and (number? event-dur-log) (= event-dur-log 3))
            (set! current-note-head grob)))))

      (listeners
       ;; Track beam events to know when beam starts/ends
       ((beam-event engraver event)
        (let ((direction (ly:event-property event 'span-direction)))
          (cond
           ((= LEFT direction)
            (set! beam-active #t)
            (set! beam-eighth-notes '()))
           ((= RIGHT direction)
            (set! beam-active #f))))))

      ((process-acknowledged engraver)
       (when current-note-head
         ;; Always add eighth notes to collection if we're in or just ended a beam
         (set! beam-eighth-notes (append beam-eighth-notes (list current-note-head)))
         (set! current-note-head #f)))

      ((stop-translation-timestep engraver)
       ;; If beam just ended and we have notes, create ties
       (when (and (not beam-active) (>= (length beam-eighth-notes) 2))
         (let loop ((notes beam-eighth-notes))
           (when (>= (length notes) 2)
              (let* ((left-nh (car notes))
                     (right-nh (cadr notes))
                     (tie (ly:engraver-make-grob engraver 'Tie left-nh)))
                (ly:spanner-set-bound! tie LEFT left-nh)
                (ly:spanner-set-bound! tie RIGHT right-nh)
                (ly:grob-set-property! tie 'direction DOWN)
                ;; Tune tie appearance using details (relative positioning)
                (let ((details (ly:grob-property tie 'details '())))
                  (ly:grob-set-property! tie 'details
                    (append details
                      '((height-limit . 0.6)           ; Smaller, flatter ties
                        (note-head-gap . 0.15)         ; Small gap below note heads
                        (ratio . 0.25)))))             ; Less curved (flatter)
                (ly:engraver-announce-end-grob engraver tie right-nh))
             (loop (cdr notes))))
         (set! beam-eighth-notes '()))
       (set! current-note-head #f))

      ((finalize engraver)
       (set! beam-eighth-notes '())
       (set! current-note-head #f)))))


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
    \override NoteHead.style = #'slash
    \hide Stem
    \alias Voice
    
    %% Ties are handled in SargamStaff context, not here
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
    \consists Auto_beam_engraver

    %% Ties for beamed eighth notes
    \consists Tie_engraver
    \consists #Sargam_beam_tie_engraver
    
    %% Tie positioning for Sargam notation (relative positioning via details)
    \override Tie.direction = #DOWN
    \override Tie.details.height-limit = #0.6
    \override Tie.details.note-head-gap = #0.15
    \override Tie.details.ratio = #0.25

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
