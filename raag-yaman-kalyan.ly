\version "2.24.0"

\include "paper.ily"
\include "raag.ly"
\language "sargam"

melodyGatI = \relative S' {
  % Start at Beat 1
  
  \da G4 \chik 4 \da G \ra Re \bar "!" %\break 
  \da G4 \diri { M8 M } \diri { P P } \diri { D D } \bar "!" \break 
  \da G4 \ra Re  \diri{P8 P} \diri{M M} \bar "!" 
  \da G8 r8 \ra G8 \da Re r \ra Re8 \da S4 |
  S n d P \bar "!" S' Re G M 
}


\language "deutsch"
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key a\major
      \transpose c d {
        \tintal
        \melodyGatI
      }
    }
%
    \new SargamStaff = "sargam" {
      \set SargamStaff.instrumentName = "Sargam"
      \key a \major

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

