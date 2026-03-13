function init() {
  initBtn();
  test();
}

function initBtn() {
  const ballBtn = document.getElementById("ball_btn");
  ballBtn.addEventListener("click", () => openBall(ballBtn));
}

// landing page
function addClassBody() {
  document.body.classList.add("open");
}

function openBall(btn) {
  btn.classList.add("shake");
  setTimeout(() => {
    btn.classList.remove("shake");
    addClassBody();
  }, 1000); // is also the loading screen for the first fetch
}

// Get Pokemon Infos for the Dex and the Cards
async function getPokemons() {
  CURRENT_LENGTH_POKEMONS = POKEMONS.length;
  try {
    const response = await fetch(OFFSET_Poke(OFFSET_FOR_URL, LOAD_LIMIT));
    const result = await response.json();
    const newPokemons = result.results;
    await getPokemonsInfos(newPokemons);
    POKEMONS.push(...newPokemons);
  } catch (er) {
    console.error(er);
  }
  showPokemons();
  OFFSET_FOR_URL = POKEMONS.length;
}

async function getPokemonsInfos(pokeArray) {
  await Promise.all(
    pokeArray.map(async (pokemon) => {
      try {
        const response = await fetch(pokemon.url);
        if (!response.ok) throw new Error("Netzwerk Antwort Fehler!");
        const result = await response.json();
        saveDatatoPokemon(pokemon, result);
      } catch (er) {
        console.error(`fehler für ${pokemon.name}: `, er);
      }
    })
  );
}

function saveDatatoPokemon(pokemon, data) {
  pokemon.weight = data.weight;
  pokemon.height = data.height;
  pokemon.id = data.id;
  pokemon.sprite_front = data.sprites.front_default;
  pokemon.sprite_back = data.sprites.back_default;
  pokemon.types = data.types.map((types) => types.type.name);
  pokemon.cries = data.cries.latest;
  pokemon.stats = data.stats.map((stats) => ({
    name: stats.stat.name,
    value: stats.base_stat,
  }));
}

function showPokemons() {
  let pokedex = document.getElementById("pokedex");
  for (let i = CURRENT_LENGTH_POKEMONS; i < POKEMONS.length; i++) {
    pokedex.innerHTML += getPokedexCard(capitalizeFirstLetter(POKEMONS[i].name), POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
  }
}

function searchPokemon() {
  const searchInput = getBoxId("search_input").value.trim().toLowerCase();
  const pokedex = getBoxId("pokedex");
  pokedex.innerHTML = "";
  for (let i = 0; i < POKEMONS.length; i++) {
    const pokemon = POKEMONS[i];
    const pokemonName = pokemon.name;
    if (pokemonName.includes(searchInput)) {
      pokedex.innerHTML += getPokedexCard(pokemonName, pokemon.id, pokemon.sprite_front, pokemon.types);
    }
  }
}
// Testing Section
function test() {
  const loadBtn = document.getElementById("load_btn");
  loadBtn.addEventListener("click", () => getPokemons());
  document.getElementById("pokedex").addEventListener("click", handelClick);
  const searchInput = getBoxId("search_input");
  searchInput.addEventListener("input", searchPokemon);
}

function handelClick(event) {
  const target = event.target.closest("[data-id]");
  console.log(target);
}
