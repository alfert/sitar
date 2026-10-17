\version "2.26.0"

\include "paper.ily"
\include "raag.ly"
\language "sargam"

%% Meend test: ascending/descending, 2 and 4 notes, octave dots above and
%% below, tivra Ma, a meend across a bar line, \da inside a meend, chik nearby.
%% Expect: slur + glissando lines on the Staff, a flat rounded arc above the
%% letters (clearing the octave dots) on the SargamStaff.
melodyI = \relative S' {
  \meend { S4 Re G M } P \meend { G8 Re }
  \meend { D4 N S' Re } \meend { Re8 S N D } P4 \meend { P2 \da M4 G }
  \meend { N,4 S } \chik 4 S2
}

\language "deutsch"
\score {
  <<
    \new Staff {
      \key d \major
      \transpose c d {
        \tintal
        \melodyI
      }
    }
    \new SargamStaff {
      \tintal
      \new SargamVoice { \melodyI }
    }
  >>
  \layout { }
}
