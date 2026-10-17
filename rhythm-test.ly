\version "2.26.0"

\include "paper.ily"
\include "raag.ly"
\language "sargam"


testRhythms = \relative S' {
  S4 r4 
  S8 S  r4 |
  \tuplet 3/2 { S8 S S} r4 
  S16 S S S r4 |
  \tuplet 5/2 { S8 S S S S } r4 r2
}

testRests = \relative S' {
  S8 r8 r4 r2 | 
  r16 r r S r4 r2 |
  S4. S4. r4 | 
  S32 S S S r8 r4 r2 
}

\language "deutsch"
\score {
  <<
    \new SargamStaff = "test1" {
      \set SargamStaff.instrumentName = "Sargam"
      \new SargamVoice = "voice1" {
        \testRhythms
        \break
        \testRests
      }
    }
    \new Staff {
      \set Staff.instrumentName = "Estern"
      \key d\major
      \time 4/4
      \transpose c d {
        \submeasureBarsOn
        
        \testRhythms
        \testRests
        
      }
    }
  >>
  \header {
    title = "Rhythm notation"
    piece = "Test 1: Simple Beamed Pair"
  }
}
