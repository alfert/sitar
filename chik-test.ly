\version "2.26.0"

\include "paper.ily"
\include "raag.ly"
\language "sargam"

%% Chikari test: quarter, eighth, sixteenth and half chiks, beaming with
%% neighbours, \relative continuity across a chik, \da on a chik.
%% Expect: slash heads on the middle line on the Staff (no accidentals), the
%% letter C on the SargamStaff, octave dots of the following notes unchanged.
melodyI = \relative S' {
  G4 \chik 4 \chik 8 \chik 8 P8 \chik 8
  \chik 16 N'16 \chik 16 \chik 16 \chik 2 S,4 \da \chik 4
}

\language "deutsch"
\score {
  <<
    \new Staff {
      \key d \major
      \transpose c d {
        \time 4/4
        \melodyI
      }
    }
    \new SargamStaff {
      \time 4/4
      \new SargamVoice { \melodyI }
    }
  >>
  \layout { }
}
