\version "2.26.0"

\include "paper.ily"
\include "raag.ly"
\language "sargam"

%% Antara (defined first: melodyGatI plays it inside the segno repeat)
melodyGatII = \relative S' {
   \break
   \sectionLabel "Antara"
   \repeat volta 2 {
     G P8 P P4 N   %\bar  "!"  
     \chik 4  N D N % \bar "!"  
     S Re G8 G P8 P  %\bar "!"  
     G r m Re r Re S4 | 
     
   }
   \break
   N4 S8 S D4 n %\bar "!"  
   D P8 P m4 G %\bar "!"  
   D G P8 P m8 m  %\bar "!"  
   G r m G r m   Re4 
   \break 
   G P8 P D4 N  %\bar "!" 
   S Re8 Re S4 N %\bar "!"  
    \break
    D8 r n D r8 n P4 %\bar "!" 
    \chik 4  
    n8 n D4  N
    \section
}


melodyGatI = \relative S' {
  
  % Start at Beat 13
  \partial 4*4
  \sectionLabel "Sthaayi"
  \chik 4
  N'8 N D4 N
  \repeat segno 2 {
    \repeat volta 2 {
      S \chik 4  S  N   
      D n8 n D4  P  
      \break
      D G P8 P m8 m 
      G r m G r m   Re4 |
    
      G P8 P D4 N  
      S Re8 Re S4 N 
      \break
      D8 r n D r8 n P4 
      \chik 4  
      n8 n D4  N 
      |
    }
    \volta 2 \fine
    \volta 1 \melodyGatII   % Antara, then D.S. al Fine
  }
}

\language "deutsch"
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key d\major
      \transpose c d {
        \submeasureBarsOn
        \tintal
        
        \melodyGatI
      }
    }
%
    \new SargamStaff = "sargam" {
      \set SargamStaff.instrumentName = "Sargam"
      \key d \major

        \submeasureBarsOn
        \tintal
        \new SargamVoice = "gatI" {
          \melodyGatI
        }

    }
    % \new Lyrics \lyricsto "gatI" { \textI }
  >>
  \header {
    title = "Hindol's Raag"
    subtitle ="Raag: Alhaiya Bilawal"  
    composer = "Hindol Deb"
  }

}

