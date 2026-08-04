\version "2.24.0"

\include "../paper.ily"
\include "raag.ly"
\language "sargam"

melodyGatI = \relative S' {
  \mark \markup {\bold A}  
  \da S4 \diri{S8 S} \diri{S8 S}  \diri{S8 S}   | 
  \da S4 \diri{S8 S} \da S4 \ra S4 | 
  \da S4 \ra S4 \diri{S8 S} \diri{S8 S}  | 
  \da S8 r8 \ra S \da S r \ra S \da S4 |
  \break   
  
  \mark \markup {\bold B}  
  \diri{S8 S}  \diri{S8 S} \da S8 r8 \ra S \da S | 
  r8 \ra S \da S4 \ra S \da S | 
  \da S \ra S  \diri{S8 S}  \diri{S8 S} | 
  \da S8 r8 \ra S \da S r \ra S \da S4 |
  \break
  
  \mark \markup {\bold C}  
  \da S4 \diri{S8 S}  \diri{S8 S} \da S4 |
  \diri{S8 S} \da S4 \diri{S8 S}  \diri{S8 S}  | 
  \da S4 \da S \diri{S8 S}  \diri{S8 S} |
  \da S8 r8 \ra S \da S r \ra S \da S4 |
  
  \bar "|."
}

\language "deutsch"
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "Melody"
      \key d \major
      \time 4/4
      \transpose c d {
        \melodyGatI
      }
    }
%
    \new SargamStaff = "sargam" {
      \set SargamStaff.instrumentName = "Sargam"
      \key d \major

      \time 4/4
        \new SargamVoice = "gatI" {
          \melodyGatI
        }

    }
    % \new Lyrics \lyricsto "gatI" { \textI }
  >>
  \header {
    title = "Sitar Lesson - Excercise 3"
    composer = "Hindol Deb"
    poet = "Play the strumming pattern on all the notes and back"
  }

}

