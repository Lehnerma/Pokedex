# Pokedex

A vanilla JavaScript Pokédex web app. No build tools, no frameworks, no package manager — plain HTML, CSS, and JS served directly in the browser.

## Project Structure

```
index.html              # Entry point, loads all CSS and JS
style.css               # Global base styles
styles/
  colors.css            # Pokémon type color variables
  fonts.css             # Font-face declarations
  pokedex.css           # Main pokédex layout
  landing.css           # Landing/pokeball opening screen
  card.css              # Pokémon detail card styles
  utilities.css         # Shared utility classes
scripts/
  script.js             # Entry point — init(), button + card wiring
  utilities.js          # DOM helpers (getBoxId, capitalizeFirstLetter, createTypes, getTypeGradient)
  data.js               # Static data: type gradients, Pokémon data array
  card.js               # Card open/close logic
  templets.js           # HTML template strings (innerHTML builders)
assets/
  img/                  # SVGs, PNGs, GIF (loading animation)
  fonts/                # Lato, Cabin, Pixelify Sans, Press Start 2P
```

## Conventions

- **No modules** — all scripts are loaded via `<script>` tags in `index.html` in dependency order. Globals are shared across files intentionally.
- **No linter/formatter** — format manually; keep consistent indentation (2 spaces).
- **JSDoc comments** on every function. Keep them concise (one-liner description + `@param`/`@returns`).
- **CSS variables** for all colours and type gradients — defined in `styles/colors.css`.
- **Template strings** for HTML — all innerHTML builders live in `templets.js`.
- **Type icons** are rendered as `<span class="type {typeName}">` elements styled entirely via CSS classes in `styles/card.css`.

## Deployment

```bash
bash up.sh "commit message"
```

`up.sh` runs: `git pull → git add . → git commit → git push`.

## API

Data is fetched from the [PokéAPI](https://pokeapi.co/). Fetching logic lives in `scripts/data.js` and `scripts/utilities.js`.

## Key Globals

| Variable | Defined in | Purpose |
|---|---|---|
| `POKEMONS` | `data.js` | Cached array of fetched Pokémon objects |
| `CURRENT_LENGTH_POKEMONS` | `data.js` | Tracks how many Pokémon are rendered (for load-more) |
| `POKEMON_TYPS` | `data.js` | Array of type objects with `value` and `gradient` |

## Ruels
- never install npm packages alone - ask evrytime!
- evry change should be documented in the logs/debug.log
- when u change something ask evrytime! 

## Verhalten
- Wenn Anforderungen unklar sind: nachfragen, nicht raten
- Lieber eine kurze Rückfrage als falsch umsetzen
- Bei größeren Aufgaben erst den Plan zeigen, dann umsetzen