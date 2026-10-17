\version "2.26.0"

\include "paper.ily"
\include "raag.ly"
\language "sargam"

%% Nested beat arcs and beat splitting (see sargam-rhythm.jpeg).
%% Expect, beat by beat:
%%   S32 S S S r8   inner arc under the four S, beat arc under all five
%%   S8 S16 S       inner arc under the last two S, beat arc under all three
%%   S8. S16        ONE arc (unequal, but no half-beat holds two events)
%%   S16 S S S      ONE arc (equal durations, no nesting)
%%   S8 r8          ONE arc under "S –"
%%   triplet        ONE arc
%%   S4. S8         "S" then "– S" under one arc (held part joins next beat)
melodyI = \relative S' {
  S32 S S S r8  S8 S16 S  S8. S16  S16 S S S |
  S8 r8 \tuplet 3/2 { S8 S S } S4. S8
}

\language "deutsch"
\score {
  <<
    \new SargamStaff {
      \time 4/4
      \new SargamVoice { \melodyI }
    }
    \new Staff {
      \time 4/4
      \melodyI
    }
  >>
  \layout { }
}
