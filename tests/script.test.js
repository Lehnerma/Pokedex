/**
 * Unit tests for list-management logic in scipts/script.js
 *
 * Covers:
 *  - renderPokemons: incremental rendering appends only new entries
 *  - resetInput:     resets CURRENT_LENGTH_POKEMONS so ALL entries re-render
 *  - searchPokemon:  filters across the complete POKEMONS array
 *  - getPokemons:    re-runs search when a search is active (no entries vanish)
 */

const fs = require("fs");
const path = require("path");

// ---------------------------------------------------------------------------
// Minimal stubs for globals that the scripts depend on.
// These must be set on `global` (= jsdom window) BEFORE injecting the script.
// ---------------------------------------------------------------------------

global.getTypeGradient = () => "#fff";
global.capitalizeFirstLetter = (val) =>
  String(val).charAt(0).toUpperCase() + String(val).slice(1);
global.createTypes = (types) =>
  types.map((t) => `<span class="type ${t}"></span>`).join("");
global.getPokedexCard = (name) =>
  `<article class="pokedex-card" data-name="${name}">${name}</article>`;
global.getBoxId = (id) => document.getElementById(id);
global.openLoadingScreen = () => {};
global.closeLoadingScreen = () => {};
global.OFFSET_Poke = (offset, limit) =>
  `https://example.com/pokemon?limit=${limit}&offset=${offset}`;

// ---------------------------------------------------------------------------
// Load the script under test
// ---------------------------------------------------------------------------
// We inject the script source as an inline <script> element so that jsdom
// (running with runScripts:"dangerously") executes it in the window/global
// context – exactly as a browser would. This makes all function declarations
// available as globals in subsequent test code.

const scriptSrc = fs.readFileSync(
  path.resolve(__dirname, "../scipts/script.js"),
  "utf8"
);

function loadScript() {
  // Reset global state (mirrors data.js)
  global.POKEMONS = [];
  global.CURRENT_LENGTH_POKEMONS = 0;
  global.OFFSET_FOR_URL = 0;
  global.LOAD_LIMIT = 20;

  // Remove any previously injected script to avoid redeclaration errors
  const old = document.getElementById("__test_script__");
  if (old) old.remove();

  const scriptEl = document.createElement("script");
  scriptEl.id = "__test_script__";
  scriptEl.textContent = scriptSrc;
  document.head.appendChild(scriptEl);
}

// ---------------------------------------------------------------------------
// Helper: build a fake pokemon object
// ---------------------------------------------------------------------------
function makePokemon(name, id) {
  return { name, id, sprite_front: `${name}.png`, types: ["normal"] };
}

// ---------------------------------------------------------------------------
// Set up a minimal DOM before each test
// ---------------------------------------------------------------------------
beforeEach(() => {
  document.body.innerHTML = `
    <div id="pokedex"></div>
    <input id="search_input" value="" />
    <dialog id="loading_screen"></dialog>
  `;
  loadScript();
  // jsdom doesn't implement dialog methods; stub them so openLoadingScreen
  // and closeLoadingScreen (declared in the injected script) don't throw.
  const dialog = document.getElementById("loading_screen");
  dialog.showModal = jest.fn();
  dialog.close = jest.fn();
});

// ===========================================================================
// renderPokemons – incremental rendering
// ===========================================================================
describe("renderPokemons", () => {
  test("renders all pokemon when CURRENT_LENGTH_POKEMONS is 0", () => {
    global.POKEMONS = [makePokemon("bulbasaur", 1), makePokemon("ivysaur", 2)];
    global.CURRENT_LENGTH_POKEMONS = 0;

    renderPokemons();

    const pokedex = document.getElementById("pokedex");
    expect(pokedex.querySelectorAll(".pokedex-card").length).toBe(2);
  });

  test("appends only new pokemon (incremental load-more behaviour)", () => {
    // Simulate first batch already rendered
    global.POKEMONS = [makePokemon("bulbasaur", 1), makePokemon("ivysaur", 2)];
    global.CURRENT_LENGTH_POKEMONS = 0;
    renderPokemons();

    // Simulate load-more: two new pokemon added
    global.CURRENT_LENGTH_POKEMONS = global.POKEMONS.length; // = 2
    global.POKEMONS.push(
      makePokemon("venusaur", 3),
      makePokemon("charmander", 4)
    );
    renderPokemons();

    const cards = document
      .getElementById("pokedex")
      .querySelectorAll(".pokedex-card");
    expect(cards.length).toBe(4);
  });

  test("does NOT re-render earlier entries (no duplicates after load-more)", () => {
    global.POKEMONS = [makePokemon("bulbasaur", 1)];
    global.CURRENT_LENGTH_POKEMONS = 0;
    renderPokemons();

    global.CURRENT_LENGTH_POKEMONS = 1;
    global.POKEMONS.push(makePokemon("ivysaur", 2));
    renderPokemons();

    // There should be exactly 2 cards total: one bulbasaur, one ivysaur
    const pokedex = document.getElementById("pokedex");
    expect(pokedex.querySelectorAll(".pokedex-card").length).toBe(2);
    expect(pokedex.querySelectorAll('[data-name="bulbasaur"]').length).toBe(1);
    expect(pokedex.querySelectorAll('[data-name="ivysaur"]').length).toBe(1);
  });
});

// ===========================================================================
// resetInput – must restore ALL entries, not just the last batch
// ===========================================================================
describe("resetInput", () => {
  test("shows all pokemon after a search is cleared", () => {
    global.POKEMONS = [
      makePokemon("bulbasaur", 1),
      makePokemon("ivysaur", 2),
      makePokemon("charmander", 3),
      makePokemon("charmeleon", 4),
    ];

    // Simulate state after second load-more (first batch already rendered)
    global.CURRENT_LENGTH_POKEMONS = 2;
    renderPokemons(); // renders only pokemon at indices 2 & 3

    // User searches for "char"
    document.getElementById("search_input").value = "char";
    searchPokemon();

    // Only "charmander" and "charmeleon" visible
    expect(
      document.getElementById("pokedex").querySelectorAll(".pokedex-card").length
    ).toBe(2);

    // User resets search – should restore all 4 pokemon
    resetInput();

    const cards = document
      .getElementById("pokedex")
      .querySelectorAll(".pokedex-card");
    expect(cards.length).toBe(4);
  });

  test("resets CURRENT_LENGTH_POKEMONS to 0", () => {
    global.POKEMONS = [makePokemon("bulbasaur", 1), makePokemon("ivysaur", 2)];
    global.CURRENT_LENGTH_POKEMONS = 2;

    resetInput();

    expect(global.CURRENT_LENGTH_POKEMONS).toBe(0);
  });

  test("clears the search input value", () => {
    document.getElementById("search_input").value = "pikachu";
    global.POKEMONS = [];

    resetInput();

    expect(document.getElementById("search_input").value).toBe("");
  });
});

// ===========================================================================
// searchPokemon – searches across the ENTIRE array
// ===========================================================================
describe("searchPokemon", () => {
  test("returns only matching pokemon", () => {
    global.POKEMONS = [
      makePokemon("bulbasaur", 1),
      makePokemon("charmander", 4),
      makePokemon("charmeleon", 5),
    ];
    document.getElementById("search_input").value = "char";

    searchPokemon();

    const cards = document
      .getElementById("pokedex")
      .querySelectorAll(".pokedex-card");
    expect(cards.length).toBe(2);
    expect(document.getElementById("pokedex").textContent).toContain(
      "charmander"
    );
    expect(document.getElementById("pokedex").textContent).toContain(
      "charmeleon"
    );
    expect(document.getElementById("pokedex").textContent).not.toContain(
      "bulbasaur"
    );
  });

  test("searches across ALL loaded pokemon, not only the last batch", () => {
    global.POKEMONS = [
      makePokemon("bulbasaur", 1), // first batch
      makePokemon("ivysaur", 2),   // first batch
      makePokemon("charmander", 4), // second batch
      makePokemon("charmeleon", 5), // second batch
    ];
    global.CURRENT_LENGTH_POKEMONS = 2; // only second batch was last loaded

    document.getElementById("search_input").value = "bulb"; // matches first batch

    searchPokemon();

    const cards = document
      .getElementById("pokedex")
      .querySelectorAll(".pokedex-card");
    expect(cards.length).toBe(1);
    expect(document.getElementById("pokedex").textContent).toContain(
      "bulbasaur"
    );
  });

  test("empty search input shows all pokemon", () => {
    global.POKEMONS = [
      makePokemon("bulbasaur", 1),
      makePokemon("charmander", 4),
    ];
    document.getElementById("search_input").value = "";

    searchPokemon();

    const cards = document
      .getElementById("pokedex")
      .querySelectorAll(".pokedex-card");
    expect(cards.length).toBe(2);
  });
});

// ===========================================================================
// getPokemons – re-runs search when active so filtered results stay correct
// ===========================================================================
describe("getPokemons (integration)", () => {
  function mockFetch(newBatch) {
    global.fetch = jest.fn((url) => {
      if (url.includes("pokemon?")) {
        return Promise.resolve({
          ok: true,
          json: () =>
            Promise.resolve({
              results: newBatch.map((p) => ({
                name: p.name,
                url: `https://example.com/${p.name}`,
              })),
            }),
        });
      }
      // Individual pokemon detail requests
      const name = url.split("/").pop();
      const pokemon = newBatch.find((p) => p.name === name);
      return Promise.resolve({
        ok: true,
        json: () =>
          Promise.resolve({
            id: pokemon.id,
            weight: 69,
            height: 7,
            sprites: {
              front_default: `${name}.png`,
              back_default: `${name}_back.png`,
            },
            types: [{ type: { name: "normal" } }],
            cries: { latest: "" },
            stats: [{ stat: { name: "hp" }, base_stat: 45 }],
          }),
      });
    });
  }

  test("appends new pokemon to existing list when no search is active", async () => {
    global.POKEMONS = [makePokemon("bulbasaur", 1), makePokemon("ivysaur", 2)];
    global.CURRENT_LENGTH_POKEMONS = 0;
    renderPokemons();
    global.CURRENT_LENGTH_POKEMONS = 2;

    const secondBatch = [
      makePokemon("charmander", 4),
      makePokemon("charmeleon", 5),
    ];
    mockFetch(secondBatch);
    document.getElementById("search_input").value = "";

    await getPokemons();

    const cards = document
      .getElementById("pokedex")
      .querySelectorAll(".pokedex-card");
    expect(cards.length).toBe(4); // all 4 pokemon present
  });

  test("re-runs search when search is active so no unfiltered entries appear", async () => {
    global.POKEMONS = [makePokemon("bulbasaur", 1), makePokemon("ivysaur", 2)];
    global.CURRENT_LENGTH_POKEMONS = 0;
    renderPokemons();
    global.CURRENT_LENGTH_POKEMONS = 2;

    // User has searched for "char"
    document.getElementById("search_input").value = "char";
    searchPokemon();
    // DOM now shows 0 matches (no char-pokemon yet)
    expect(
      document.getElementById("pokedex").querySelectorAll(".pokedex-card").length
    ).toBe(0);

    // Load More is clicked – second batch contains char-pokemon
    const secondBatch = [
      makePokemon("charmander", 4),
      makePokemon("charmeleon", 5),
    ];
    mockFetch(secondBatch);

    await getPokemons();

    // Search is still active: DOM must show only matching pokemon
    const cards = document
      .getElementById("pokedex")
      .querySelectorAll(".pokedex-card");
    expect(cards.length).toBe(2);
    expect(document.getElementById("pokedex").textContent).toContain(
      "charmander"
    );
    expect(document.getElementById("pokedex").textContent).toContain(
      "charmeleon"
    );
    expect(document.getElementById("pokedex").textContent).not.toContain(
      "bulbasaur"
    );
  });

  test("old entries are NOT lost after load-more when search is cleared afterwards", async () => {
    global.POKEMONS = [makePokemon("bulbasaur", 1), makePokemon("ivysaur", 2)];
    global.CURRENT_LENGTH_POKEMONS = 0;
    renderPokemons();
    global.CURRENT_LENGTH_POKEMONS = 2;

    const secondBatch = [makePokemon("charmander", 4)];
    mockFetch(secondBatch);
    document.getElementById("search_input").value = "";

    await getPokemons();

    // All 3 pokemon visible
    expect(
      document.getElementById("pokedex").querySelectorAll(".pokedex-card").length
    ).toBe(3);

    // User searches then resets
    document.getElementById("search_input").value = "char";
    searchPokemon();
    resetInput();

    // ALL 3 must be back
    expect(
      document.getElementById("pokedex").querySelectorAll(".pokedex-card").length
    ).toBe(3);
  });
});

