\version "2.26.0"

\include "paper.ily"
\include "raag.ly"
\language "sargam"

melodyGatI = \relative S' {
  
  % Start at Beat 5
  \partial 4*4
  \chik 4 
    N'8 N D4 N
    
  \repeat volta 2 {
     
    S^\markup{Fine}  \chik 4  S  N  \bar "!" 
    D n8 n D4  P |
    
    D G P8 P m8 m   \bar "!"  
    G r m G r m   Re4 |
    
    G P8 P D4 N \bar "!" 
    S Re8 Re S4 N |
    D8 r n D r8 n \bar "!" 
    P4 \chik 4  
    N8 N D4 N 
  }
  % \bar ":|."
  
}


\language "deutsch"
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key d\major
      \transpose c d {
        \jattaal
        \melodyGatI
      }
    }
%
    \new SargamStaff = "sargam" {
      \set SargamStaff.instrumentName = "Sargam"
      \key d \major

        \jattaal
        \new SargamVoice = "gatI" {
          \melodyGatI
        }

    }
    % \new Lyrics \lyricsto "gatI" { \textI }
  >>
  \header {
    title = "Hindol's Raag"
    composer = "Hindol Deb"
  }

}



%{
convert-ly (GNU LilyPond) 2.26.0  convert-ly: Processing `'...
Applying conversion: 2.25.0, 2.25.1, 2.25.2, 2.25.3, 2.25.4, 2.25.5,
2.25.6, 2.25.8, 2.25.9, 2.25.11, 2.25.12, 2.25.13, 2.25.18, 2.25.22,
2.25.23, 2.25.24, 2.25.25, 2.25.26, 2.25.28, 2.25.30, 2.25.31,
2.25.32, 2.25.33, 2.25.34, 2.25.35, 2.25.80, 2.26.0
%}
