\version "2.24.0"

\include "../paper.ily"
\include "raag.ly"
\language "sargam"

melodyGatI = \relative S' {
  \mark \markup {\bold A}  
  \da S4 \diri{Re8 Re} \da G4 \ra m |  
  \da P4 \diri{D8 D} \da N4 \ra S | 
  \da S4 \diri {N8 N} \da D4 \ra P |
  \da m \diri {G8 G} \da Re4 \ra S |
  \break   
  
  \mark \markup {\bold B}  
  \da S4 \ra Re \diri{G8 G} \diri{m8 m}  | 
  \da P4 \ra D \diri{N8 N} \diri{S8 S}  | 
  \da S4 \ra N \diri{D8 D} \diri{P8 P}  | 
  \da m4 \ra G \diri{Re8 Re} \diri{S8 S}  | 
  \break
  
  \mark \markup {\bold C}  
  \diri{S8 S} \diri{Re8 Re}  \da G4 \ra m  | 
  \diri{P8 P} \diri{D8 D}  \da N4 \ra S  | 
  \diri{S8 S} \diri{N8 N}  \da D4 \ra P  | 
  \diri{m8 m} \diri{G8 G}  \da Re4 \ra S  | 
  
  \bar "|."
}

\language "deutsch"
\score {
  <<
    \new Staff {
      \set Staff.instrumentName = "melody"
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
    title = "Sitar Lesson - Excercise 2"
    composer = "Hindol Deb"
    poet = "Play the strumming pattern exactly as written"
  }

}

