\version "2.24.0"

\include "../paper.ily"
\include "raag.ly"


melodyGatI = \relative S' {
  % Start at Beat 1
  % Beams are automatic: LilyPond decides the grouping and the Sargam
  % grouping arc follows it (no explicit [ ] needed).
  G4 \chik G Re \bar "!"\break G M8 M P P D D \bar "!" \break G4 Re P8 P M M \bar "!" G8 r8 G8 Re r Re8 S4 |
  S2
}

textI = \lyricmode {
  G G Re G M M P P D D G Re P P M M Gr G Re  Re S |
}


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
%
    \new SargamStaff = "sargam" {
      \set SargamStaff.instrumentName = "Sargam"
      \key D \major
      
        \tintal
        \new SargamVoice = "gatI" {
          \melodyGatI 
        }
      
    }
    % \new Lyrics \lyricsto "gatI" { \textI }
  >>
  \header {
    title = "Raag Yalman Kalyan"
    composer = "Josh Feinburg"
  }
  
}

