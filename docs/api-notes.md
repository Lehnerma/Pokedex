# PokéAPI v2 Documentation

## Overview
_Source: https://pokeapi.co/docs/v2_
_Researched: 2026-06-02_

- **Base URL:** `https://pokeapi.co/api/v2/`
- **Authentication:** Not required — all resources are publicly accessible
- **Rate limits:** None (static hosting since Nov 2018); fair use expected via local caching
- **Methods:** GET only (read-only API)

---

## Core Endpoints

### Pokémon
- **URL:** `/pokemon/{id or name}/`
- **Returns:** Stats, abilities, moves, forms, sprites, held items
- **Example:** `/pokemon/bulbasaur/` or `/pokemon/1/`

### Pokémon Species
- **URL:** `/pokemon-species/{id or name}/`
- **Returns:** Species classification, flavor text, evolution chain ID, habitat
- **Example:** `/pokemon-species/bulbasaur/`

### Types
- **URL:** `/type/{id or name}/`
- **Returns:** Type effectiveness (double damage to/from), Pokémon in type, moves of type
- **Example:** `/type/grass/` or `/type/1/`

### Moves
- **URL:** `/move/{id or name}/`
- **Returns:** Power, accuracy, effect, priority, target, physical/special classification
- **Example:** `/move/vine-whip/`

### Items
- **URL:** `/item/{id or name}/`
- **Returns:** Item effect, category, cost, attributes
- **Example:** `/item/poke-ball/`

### Evolution Chains
- **URL:** `/evolution-chain/{id}/`
- **Returns:** Evolution trigger (level, trade, item, etc.), conditions, evolution sequence
- **Note:** ID only (no name lookup)

### Other Notable Endpoints
- `/ability/{id or name}/` — Passive Pokémon effects
- `/generation/{id or name}/` — Game generation groupings
- `/region/{id or name}/` — Geographic areas

---

## Pagination

**Default:** 20 results per page

**Query Parameters:**
- `limit=<number>` — Set page size (e.g., `?limit=60`)
- `offset=<number>` — Skip N results for pagination (e.g., `?offset=60`)

**Example:** `/pokemon?limit=60&offset=60`

**Response structure:** 
- Named endpoints: Include `name`, `url` fields in results
- Unnamed endpoints (evolution-chain, machine): Include only `url` field

---

## Key Constraints

- **GET only** — No POST, PUT, DELETE
- **No request body** — All parameters via query string or URL path
- **Fair use caching** — Local caching of responses strongly recommended
- **Stable IDs** — Pokémon, types, moves have stable numeric IDs and canonical names
