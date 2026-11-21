# Design mapping

Source of truth: [`docs/design/wonderly-all-screens.html`](design/wonderly-all-screens.html)
(23 screens, 390 x 844). Palette, type and spacing tokens are in
`lib/core/theme`.

| # | Design screen | Implementation |
|---|---|---|
| 1 | Splash | `features/onboarding/.../splash_page.dart` |
| 2-4 | Welcome: learn by playing / collect stars / for grown-ups | `onboarding_page.dart` (one `PageView`), art in `onboarding_art.dart` |
| 5 | Create profile | `features/profile/.../profile_setup_page.dart` |
| 6 | Home | `features/home/.../home_page.dart` |
| 7 | Subjects | `features/learning/.../subjects_page.dart` |
| 8 | Zoology | `features/learning/.../subject_page.dart` (works for any subject with several sets) |
| 9 | Quiz: question 3 | `quiz_page.dart` + `choice_question_view.dart` |
| 10 | Quiz: answer chosen | same screen, `selected` state |
| 11 | Quiz: correct answer | same screen, `revealed` + `FeedbackPanel` |
| 12 | Quiz: try again | same screen, wrong-answer feedback |
| 13 | Quiz: results | `results_page.dart` |
| 14 | Geometry lesson | `shape_match_view.dart` (drag and match) |
| 15 | Plant ecosystems lesson | `choice_question_view.dart` text list with scene |
| 16 | Logic puzzle | `pattern_question_view.dart` |
| 17 | Rewards | `features/progress/.../rewards_page.dart` |
| 18 | Badge unlocked | `badge_unlocked_page.dart` |
| 19 | Progress | `progress_page.dart` |
| 20 | Profile | `features/profile/.../profile_page.dart` |
| 21 | Parent gate | `features/parent/.../parent_gate_page.dart` |
| 22 | Grown-ups dashboard | `grown_ups_page.dart` |
| 23 | Settings | `features/settings/.../settings_page.dart` |

Illustrations in `assets/svg` were extracted unchanged from the design file
(owl, cat, fox, rabbit, lion, shapes, plant, sun, water drop, outlines). The
24 px line icons use Material icons so they follow text scaling and platform
conventions.

## Deliberate deviations

| Design | Implementation | Why |
|---|---|---|
| Demo data (Alex, 26 stars, 4-day streak) | Real persisted state, starting at zero | The design is a mock-up |
| "Continue (demo)" on the parent gate | Removed | A bypass defeats the gate |
| Gate answer boxes show fixed `7 x 4` | Random 6-9 factors, lockout after 3 misses | Memorisable questions are weak gates |
| "Switch learner" on Profile | Omitted | One learner per install in v1; avoids a destructive profile swap |
| Home hero uses the cat | Uses the child's chosen buddy | Personalisation |
| Quiz feedback "Roar-some!" | Generic cheers, plus the question's own fact | Wording must fit every subject |
| Wrong-answer line "You will see this again soon" | "Every try helps you learn" | The app does not re-queue missed questions, so the promise would be false |
| Results "+12 stars" | Computed: 1 per new correct answer, +4 first completion, +5 per badge | Real rules instead of fixed text |
| Separate screens per welcome step | One `PageView` with the same three slides | Same look, one route, swipe support |
| Review answers (no detail in design) | Bottom sheet listing each answer | Needed a real behaviour behind the button |
| Locked "Ocean life" | Unlocks at 30 stars as written | Matches design copy |
| Settings: bedtime toggle | Requires the parent gate | A child could otherwise switch bedtime mode off |
| Numbers / Words tiles | "Coming soon" snackbar | Content not designed yet |

Screens not in the design but required for a working product: the **break
screen** (shown when the daily limit or bedtime ends play) and the
**help / privacy sheets** in Settings.
