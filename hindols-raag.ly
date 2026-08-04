\version "2.24.0"

\include "../paper.ily"
\include "raag.ly"
\language "sargam"

melodyGatI = \relative S' {
  % Start at Beat 1
  
  S'4 N8 N D4 N \bar "!" 
  S \chik 4 S N |
  D n8 n D4 P 
  \bar "!" 
  D G P8 P m m | 
  G8 r8 m G r m Re4 \bar "!" 
  G8 G P4 D N |
  S Re8 Re S4 N \bar "!" 
  D8 r n D r8 n P4 | 
  \chik 4 S N8 N D4 \bar "!" 
  N S8 r \chik 8 S r8 \chik 8 
  \bar ":|."
  
}


\language "deutsch"
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key a\major
      \transpose c d {
        \jattaal
        \melodyGatI
      }
    }
%
    \new SargamStaff = "sargam" {
      \set SargamStaff.instrumentName = "Sargam"
      \key a \major

        \jattaal
        \new SargamVoice = "gatI" {
          \melodyGatI
        }

    }
    % \new Lyrics \lyricsto "gatI" { \textI }
  >>
  \header {
    title = "Raaga A"
    composer = "Hindol Deb"
  }

}

