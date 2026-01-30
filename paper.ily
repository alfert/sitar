#(set-global-staff-size 18)
\paper {
  #(include-special-characters)
  % #(define fonts
%     (make-pango-font-tree "Optima"
%                           "Arial"
%                           "Luxi Mono"
%      1
%    ))
  #(define fonts
    (set-global-fonts
     #:music "emmentaler"
     #:brace "emmentaler"
     #:roman "Optima"
     #:sans "MuseJazzText"
     #:typewriter "Franklin Gothic Medium"
     #:factor (/ staff-height pt 18)
     ))
  ragged-bottom = ##t
  print-all-headers = ##t
  tocTitleMarkup = \markup \huge \bold \column {
    \fill-line { \null "Inhaltsverzeichnis" \null }
    \hspace #1
  }
  tocCDMarkup = \markup \large \column {
    \hspace #1
    \fill-line { \null \italic \fromproperty #'toc:text \null }
    \hspace #1
  }
}

jazzChords = {
  \set majorSevenSymbol = \markup { maj7 }
  %% \set chordNameExceptions = #chExceptions
  \set chordChanges = ##t
  \semiGermanChords  
}

%% Adds a CD-Title to the ToC
tocCD =
#(define-music-function (parser location text) (markup?)
  (add-toc-item! 'tocCDMarkup text))


ek-ong-kar = \markup{ \override #'(font-name . "Raaj Script Medium") { ੴ } }