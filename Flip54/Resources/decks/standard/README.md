# Standard Deck Artwork

Drop 55 PNG/SVG files here named per `CardImageProvider` convention:

| File                              | Description            |
|-----------------------------------|------------------------|
| `standard-back.png`               | Card back              |
| `standard-{rank}-{suit}.png`      | All 52 standard cards  |
| `standard-joker-red.png`          | Red joker              |
| `standard-joker-black.png`        | Black joker            |

**Rank values:** `ace two three four five six seven eight nine ten jack queen king`  
**Suit values:** `hearts spades clubs diamonds`

Example: `standard-seven-hearts.png`, `standard-ace-spades.png`, `standard-king-clubs.png`

Once files are added, run `xcodegen generate` to include them in the bundle.
