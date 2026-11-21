# Content guide

All quiz content lives in [`assets/data/questions.json`](../assets/data/questions.json).
The app never trusts it blindly: `CatalogParser` and `ValidateQuestion` skip
anything malformed, and a unit test fails the build if an authored question is
rejected.

## Structure

```jsonc
{
  "version": 1,
  "sets": [
    {
      "id": "zoology_quiz",          // unique, snake_case
      "subject": "zoology",          // zoology | geometry | plants | logic
      "title": "Zoology Quiz",
      "art": "cat",                  // illustration key for cards (optional)
      "unlockStars": 30,             // optional: locked until the child has this many stars
      "questions": [ /* see below */ ]
    }
  ]
}
```

### Question types

```jsonc
// Pick one. layout: "grid" (picture cards) or "list" (text buttons)
{"type": "choice", "id": "zoo-3", "prompt": "Which animal is an apex predator?",
 "layout": "grid",
 "options": [{"label": "Fox", "art": "fox"}, {"label": "Lion", "art": "lion"}],
 "answer": 1,                      // index into options
 "scene": ["sun", "water_drop"],   // optional pictures above a list question
 "hint": "Nothing hunts this animal.",
 "fact": "Lions sit at the top of their food chain."}

// Finish the pattern
{"type": "pattern", "id": "logic-1", "prompt": "What comes next?",
 "sequence": ["circle", "square", "circle", "square"],
 "options": ["circle", "square", "star"], "answer": 0}

// Drag each shape to its outline
{"type": "match", "id": "geo-1", "prompt": "Drag each shape to its match",
 "shapes": ["circle", "triangle", "square"]}
```

Illustration keys come from `lib/core/widgets/art_view.dart`: `owl`, `cat`,
`fox`, `rabbit`, `lion`, `shape_circle`, `shape_triangle`, `shape_square`,
`shape_star`, `plant_pot`, `water_drop`, `sun` (shape sequences may use the
short names `circle`, `triangle`, `square`, `star`).

## Rules every question must satisfy

1. Unique `id` across the whole file.
2. Prompt of **15 words or fewer**, readable at grade 3.
3. 2 or more options, all non-blank and **distinct**; `answer` is a valid index.
4. Vary the position of the right answer; do not always use the first option.
5. Facts must be correct for children and phrased positively. Avoid trivia
   with debated answers (for example, which animals are nocturnal).
6. A `fact` is shown after answering, so write it as a short, friendly
   explanation of why the answer is right.
7. No personal data, brand names or external links.

## Review checklist for a new batch

- [ ] A second person verified every factual claim.
- [ ] `flutter test test/unit/learning/catalog_test.dart` passes (no rejected questions).
- [ ] Wrong options are plausible but unambiguous.
- [ ] Pattern questions: the answer extends the repeating unit.
- [ ] Read aloud sounds natural when the prompt and options are spoken.

## Counts today

Zoology: Mammals (6), Zoology Quiz (10), Birds (6), Ocean life (5, locked at
30 stars). Geometry: 6. Plants: 8. Logic: 9. Total 50 questions. The product
plan targets about 150; extend this file, or add a generator behind
`CatalogRepository` (see [ROADMAP](ROADMAP.md)).
