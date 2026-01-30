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

#(define (Voice_line_engraver context)
   (let (
         ;; Current follower
         (follower #f)
         ;; Note head grob acknowledged
         (note-head #f)
         ;; Moment at which the follower should end. If there is no note head
         ;; at that moment (e.g., because there is a rest), it is removed.
         (expected-end-mom #f)
         ;; Track if we're inside a beam
         (beam-active #f))
     (make-engraver
       (acknowledgers
        ((note-head-interface engraver grob source-engraver)
         ;; Only acknowledge note heads that are NOT beamed eighth notes
         (let* ((cause (ly:grob-property grob 'cause))
                (event-dur-log (if (ly:stream-event? cause)
                                   (ly:duration-log (ly:event-property cause 'duration))
                                   #f)))
           ;; Skip beamed eighth notes (event dur-log = 3)
           (when (not (and beam-active (number? event-dur-log) (= event-dur-log 3)))
             (set! note-head grob)))))

      (listeners
       ;; Track beam events to know when we're inside a beam
       ((beam-event engraver event)
        (let ((direction (ly:event-property event 'span-direction)))
          (cond
           ((= LEFT direction) (set! beam-active #t))
           ((= RIGHT direction) (set! beam-active #f))))))

      ((process-acknowledged engraver)
       (when note-head
         ;; End the previous follower on this note head.
         (when follower
           (ly:spanner-set-bound! follower RIGHT note-head)
           (ly:engraver-announce-end-grob engraver follower note-head)
           (set! follower #f)
           (set! expected-end-mom #f))
         ;; Create a new follower starting from this note head.
         ;; (set! follower (ly:engraver-make-grob engraver 'VoiceFollower note-head))
         (set! follower (ly:engraver-make-grob engraver 'Slur note-head))
         (ly:spanner-set-bound! follower LEFT note-head)
         ;; Record the moment at which we expect the follower to end.
         (set! expected-end-mom
               (let ((current (ly:context-current-moment context))
                     (note-event (ly:grob-property note-head 'cause)))
               (ly:moment-add current (ly:event-length note-event current))))
         (set! note-head #f)))
      ((stop-translation-timestep engraver)
       ;; If the follower reached its expected end moment without finding
       ;; a note head to end on (e.g., because of a rest), remove it.
       (let ((current (ly:context-current-moment context)))
         (when (and expected-end-mom (moment<=? expected-end-mom current))
           (ly:grob-suicide! follower)
           (set! follower #f)
           (set! expected-end-mom #f)))
       ;; Bookkeeping
       (set! note-head #f))
      ((finalize engraver)
       ;; Remove any unterminated follower
       (when follower
         (ly:grob-suicide! follower))))))

#(define (Remove_voice_line_when_slur_engraver context)
   (let (
         ;; Any voice follower started in this time step
         (started-voice-follower #f)
         ;; Any voice follower ended in this time step
         (ended-voice-follower #f)
         ;; The currently "active" voice follower; a follower is active
         ;; from its start time step included to its end time step excluded.
         (active-voice-follower #f)
         ;; The voice follower that was active at the previous time step.
         (previous-active-voice-follower #f)
         ;; Any slur started in this time step
         (started-slur #f)
         ;; Any slur started in the previous time step
         (previous-started-slur #f)
         ;; Any slur of which we acknowledge the end, meaning that it ended
         ;; in the *previous* time step.
         (previous-ended-slur #f)
         ;; The slur that was active in the previous time step.
         (previous-active-slur #f))
     (make-engraver
      (acknowledgers
       ((line-spanner-interface engraver grob source-engraver)
        ;; Ideally, we'd have a specific interface for VoiceFollower,
        ;; but it doesn't exist.
        ;;(when (eq? 'VoiceFollower (grob::name grob))
        (when (eq? 'Slur (grob::name grob))
          (set! started-voice-follower grob)))
       ((slur-interface engraver grob source-engraver)
        (set! started-slur grob)))
      (end-acknowledgers
       ((line-spanner-interface engraver grob source-engraver)
        ;;(when (eq? 'VoiceFollower (grob::name grob))
        (when (eq? 'Slur (grob::name grob))
          (set! ended-voice-follower grob)))
       ((slur-interface engraver grob source-engraver)
        (set! previous-ended-slur grob)))
      ((stop-translation-timestep engraver)
       ;; Determine if there was an active slur in the previous time step.
       (when previous-ended-slur
         (set! previous-active-slur #f)
         (set! previous-ended-slur #f))
       (when previous-started-slur
         (set! previous-active-slur previous-started-slur))
       ;; If a voice follower and a slur were both active in the previous
       ;; time step, remove the voice follower.
       (when (and previous-active-voice-follower previous-active-slur)
         (ly:grob-suicide! previous-active-voice-follower))
       ;; Determine if there was an active voice follower in this time step
       (when ended-voice-follower
         (set! active-voice-follower #f)
         (set! ended-voice-follower #f))
       (when started-voice-follower
         (set! active-voice-follower started-voice-follower)
         (set! started-voice-follower #f))
       ;; Set previous-* variables for the next time step.
       (set! previous-active-voice-follower active-voice-follower)
       (set! previous-started-slur started-slur)
       (set! started-slur #f)))))



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

    %% Voice lines for non-beamed notes (meend/glissando)
    %% \consists #Voice_line_engraver
    %% \consists #Remove_voice_line_when_slur_engraver

    %% Ties for beamed eighth notes
    \consists Tie_engraver
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
