\version "2.24.0"

\include "../paper.ily"
\include "raag.ly"
\language "sargam"

melodyGatI = \relative S' {
  % Start at Beat 1
  % Beams are automatic: LilyPond decides the grouping and the Sargam
  % grouping arc follows it (no explicit [ ] needed).
  \da G4 \chik 4 \da G \ra Re \bar "!" %\break 
  \da G4 \diri { M8 M } \diri { P P } \diri { D D } \bar "!" \break 
  \da G4 \ra Re  \diri{P8 P} \diri{M M} \bar "!" 
  \da G8 r8 \ra G8 \da Re r \ra Re8 \da S4 |
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

