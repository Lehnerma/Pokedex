function init() {
  initBtn();
  initCard();
}

function initBtn() {
  const BALL_BTN = document.getElementById("ball_btn");
  BALL_BTN.addEventListener("click", () => openBall(BALL_BTN));
  const SEARCH = getBoxId("search_input");
  SEARCH.addEventListener("input", searchPokemon);
}

function showPokemons() {
  let pokedex = getBoxId("pokedex");
  for (let i = CURRENT_LENGTH_POKEMONS; i < POKEMONS.length; i++) {
    pokedex.innerHTML += getPokedexCard(POKEMONS[i].name, POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
  }
}

function addClassBody() {
  document.body.classList.add("open");
}

function openBall(btn) {
  btn.classList.add("shake");
  btn.disabled = true;
  getPokemons();
  setTimeout(() => {
    btn.classList.remove("shake");
    addClassBody();
  }, 1500);
}

async function getPokemons() {
  CURRENT_LENGTH_POKEMONS = POKEMONS.length;
  openLoadingScreen();
  try {
    const RESPONSE = await fetch(OFFSET_Poke(OFFSET_FOR_URL, LOAD_LIMIT));
    const RESULT = await RESPONSE.json();
    const NEW_POKEMON = RESULT.results;
    await getPokemonsInfos(NEW_POKEMON);
    POKEMONS.push(...NEW_POKEMON);
  } catch (er) {
    console.error(er);
  }
  showPokemons();
  closeLoadingScreen();
  OFFSET_FOR_URL = POKEMONS.length;
}

async function getPokemonsInfos(pokeArray) {
  await Promise.all(
    pokeArray.map(async (pokemon) => {
      try {
        const response = await fetch(pokemon.url);
        if (!response.ok) throw new Error("Netzwerk Antwort Fehler!");
        const result = await response.json();
        saveDataToPokemon(pokemon, result);
      } catch (er) {
        console.error(`fehler für ${pokemon.name}: `, er);
      }
    })
  );
}

function saveDataToPokemon(pokemon, data) {
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

function openLoadingScreen() {
  if (!POKEMONS.length > 0) return;
  const dialog = getBoxId("loading_screen");
  dialog.showModal();
}

function closeLoadingScreen() {
  if (!POKEMONS.length > 0) return;
  const dialog = getBoxId("loading_screen");
  dialog.close();
}
