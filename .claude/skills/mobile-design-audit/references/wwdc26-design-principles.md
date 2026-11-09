# WWDC26 session 250: design principles (notes)

Our notes from the 17-minute WWDC26 talk by two Apple design evangelists. The
talk introduces the design principles page in the HIG. These notes are a
paraphrase for audit use, not a transcript.

## What design is

Design is making something with intention: focus on what matters most to
people. Every feature asks for time, attention, and trust, so choosing what to
build is often choosing what to leave out. There is no formula for combining
the principles; leaning into one can feel like giving up another, and the
designer has to judge.

## The principles, with the talk's examples

1. **Purpose.** Ask whether what you make has a purpose before you sketch or
   code.
2. **Agency.** Offer choices; let people dive in instead of following a fixed
   path. People make mistakes, so offer forgiveness: easy undo for everything,
   and a double check only before something destructive. Interrupt rarely,
   only before a big mistake.
3. **Responsibility.** Privacy is a human right. An app that asks for
   permissions the second it opens is like a stranger who demands your phone
   number before saying why. Ask at the right moment, only for what is needed,
   and say what it is for. Ask how a feature could be misused and who could be
   harmed. For AI: expect wrong or unexpected output (example: a recipe app
   suggesting an ingredient a person logged as an allergy). Add previews,
   confirmations, and disclaimers, and remove a feature if its risk outweighs
   its value.
4. **Familiarity.** Use metaphors people know (the trash can: things go in,
   and can come back out). A metaphor must be neither too literal nor too
   abstract. Never use a familiar symbol for a different action, and do not
   restyle common icons. Things that look the same should behave the same, and
   actions should stay in the same place across screens and devices.
5. **Flexibility.** People use the same app at home, on a run, and while
   driving; each context needs its own interaction. Each device deserves a
   design that uses what makes it unique (quick touch on iPhone, deep
   workflows on Mac). Learn who the audience is: age, language, expertise,
   accessibility needs. When no single layout fits everyone, let people
   personalise: rearrange controls or hide ones they never use.
6. **Simplicity.** Simple is not minimal: hiding everything in one menu looks
   minimal but is not simple. Simple means concise (plain language, no jargon,
   no repetition, fewer steps) and clear (hierarchy through order, spacing,
   and contrast, so the most important thing is the most obvious). Clear
   interfaces answer: what do I look at, what can I interact with, and how.
   Turn complex data into a graphic or a summary where that helps. Sometimes
   simple means adding context: a play button that also shows time left.
   You have arrived when you have exactly enough.
7. **Craft.** People notice shortcuts: a button that makes you wait, jittery
   scrolling, misaligned icons, a layout that breaks on rotation. Quality
   materials are good fonts, colours that adapt to light and dark, clear
   icons, responsive animations with immediate feedback, and reliable,
   secure foundations. Craft comes from iteration, and it continues after
   launch as the platform changes.
8. **Delight.** Not confetti or extra flourishes added at the end. Decide the
   emotion you want (relaxed, confident, excited) and reinforce it. Delight is
   the result of getting the other principles right: agency to act, safety to
   explore, familiar patterns, and the ability to make it your own.

## Audit use

- Run the questions in `principles.md` on each screen.
- When two principles conflict (for example flexibility adds settings,
  simplicity removes them), write down the trade-off and the choice.
