\version "2.24.0"

\include "../paper.ily"
\include "raag.ly"


melodyGatI = \relative S' {
  % Start at Beat 1
  G4 \chik G Re \bar "!"\break G M8[ M] P P D D \bar "!" \break G4 Re P8 P M M \bar "!" G8 r8 G8 Re r Re8 S4 |
  S2
}

textI = \lyricmode {
  G G Re G M M P P D D G Re P P M M Gr G Re  Re S |
}

\layout {
  \context {
    \Voice
    \consists #Voice_line_engraver
    \consists #Remove_voice_line_when_slur_engraver
    %\override VoiceFollower.style = #'slur
    %\slurDashed
    }
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
    \new Staff {
      \set Staff.instrumentName = "Sargam Voice"
      \key D \major
      \transpose S Re {
        \tintal
        \new SargamVoice {
          \melodyGatI 
        }
      }
    }
    \new SargamStaff = "my fist sargam staff" {
      \set SargamStaff.instrumentName = "Sargam Staff"
      \key D \major
      
        \tintal
        \new SargamVoice = "gatI" {
          \melodyGatI 
        }
      
    }
    \new Lyrics \lyricsto "gatI" { \textI }
  >>
  \header {
    title = "Raag Yalman Kalyan"
    composer = "Josh Feinburg"
  }
  
}

