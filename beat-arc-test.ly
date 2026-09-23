\version "2.24.0"

\include "paper.ily"
\include "raag.ly"

%% Test cases for the per-beat grouping arc (Sargam_beat_arc_engraver)

testSimplePair = \relative S' {
  % Simple pair of beamed eighth notes
  S8[ Re] G4
}

testMultipleBeams = \relative S' {
  % Multiple separate beams
  S8[ Re] G8[ M] P8[ D] N4
}

testLongBeam = \relative S' {
  % Four eighth notes in one beam
  S8[ Re G M] P4
}

testMixedDurations = \relative S' {
  % Mix of eighth notes and quarter notes
  S4 Re8[ G] M4 P8[ D] N2
}

testWithRests = \relative S' {
  % Beams with rests between
  S8[ Re] r8 G8[ M] r4
}

textSimple = \lyricmode {
  S Re G
}

textMultiple = \lyricmode {
  S Re G M P D N
}

textLong = \lyricmode {
  S Re G M P
}

textMixed = \lyricmode {
  S Re G M P D N
}

textRests = \lyricmode {
  S Re G M
}

\score {
  <<
    \new SargamStaff = "test1" {
      \set SargamStaff.instrumentName = "Simple Pair"
      \new SargamVoice = "voice1" {
        \testSimplePair
      }
    }
    \new Lyrics \lyricsto "voice1" { \textSimple }
  >>
  \header {
    piece = "Test 1: Simple Beamed Pair"
  }
}

\score {
  <<
    \new SargamStaff = "test2" {
      \set SargamStaff.instrumentName = "Multiple Beams"
      \new SargamVoice = "voice2" {
        \testMultipleBeams
      }
    }
    \new Lyrics \lyricsto "voice2" { \textMultiple }
  >>
  \header {
    piece = "Test 2: Multiple Separate Beams"
  }
}

\score {
  <<
    \new SargamStaff = "test3" {
      \set SargamStaff.instrumentName = "Long Beam"
      \new SargamVoice = "voice3" {
        \testLongBeam
      }
    }
    \new Lyrics \lyricsto "voice3" { \textLong }
  >>
  \header {
    piece = "Test 3: Four Notes in One Beam"
  }
}

\score {
  <<
    \new SargamStaff = "test4" {
      \set SargamStaff.instrumentName = "Mixed Durations"
      \new SargamVoice = "voice4" {
        \testMixedDurations
      }
    }
    \new Lyrics \lyricsto "voice4" { \textMixed }
  >>
  \header {
    piece = "Test 4: Eighth Notes Mixed with Other Durations"
  }
}

\score {
  <<
    \new SargamStaff = "test5" {
      \set SargamStaff.instrumentName = "With Rests"
      \new SargamVoice = "voice5" {
        \testWithRests
      }
    }
    \new Lyrics \lyricsto "voice5" { \textRests }
  >>
  \header {
    piece = "Test 5: Beams Separated by Rests"
  }
}

\header {
  title = "Sargam Beat-Arc Engraver Test Suite"
  subtitle = "One grouping arc per beat; note count = subdivision (rests count too)"
}
