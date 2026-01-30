\version "2.24"

\include "raag.ly"

%% MUSIK

raagMhegGatI = \relative S' {
  % Start at Beat 8
  m8( M Re S) Re n
  S 
  % g8 g e d c d 
  
  Re4 \chik 
  % e4 \chik 
  
  P-> m \glissando Re
  Re2
  % a g \glissando e 
  % n \glissando P
  % c \glissando a
}



\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key Re \major
      \transpose S Re {
        \jhaptal
        { r2 r2. r2 }
        \raagMhegGatI 
      }
    }
    \new Staff {
      \set Staff.instrumentName = "Sargam Voice"
      \key Re \major
      \transpose S Re {
        \jhaptal
        \new SargamVoice {
          { r2 r2. r2 }
          \raagMhegGatI 
        }
      }
    }
    \new SargamStaff = "my fist sargam staff" {
      \set SargamStaff.instrumentName = "Sargam Staff"
      \key Re \major
      
        \jhaptal
        \new SargamVoice {
          { r2 r2. r2 }
          \raagMhegGatI 
        }
      
    }
  >>
}
