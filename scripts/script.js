function init() {
  initBtn();
  initCard();
}

function initBtn() {
  const BALL_BTN = document.getElementById("ball_btn");
  BALL_BTN.addEventListener("click", () => openBall(BALL_BTN));
  const SEARCH = getBoxId("search_input");
  const SEARCH_BTN = getBoxId("search_btn");
  const RESET_SEARCH_BTN = getBoxId("reset_btn");
  SEARCH.addEventListener("change", searchPokemon);
  SEARCH_BTN.addEventListener("click", searchPokemon);
  RESET_SEARCH_BTN.addEventListener("click", resetInput);
}

function renderPokemons() {
  let POKEDEX = getBoxId("pokedex");
  for (let i = CURRENT_LENGTH_POKEMONS; i < POKEMONS.length; i++) {
    POKEDEX.innerHTML += getPokedexCard(POKEMONS[i].name, POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
  }
}

function renderAllPokemons() {
  let POKEDEX = getBoxId("pokedex");
  for (let i = 0; i < POKEMONS.length; i++) {
    POKEDEX.innerHTML += getPokedexCard(POKEMONS[i].name, POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
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
  renderPokemons();
  closeLoadingScreen();
  OFFSET_FOR_URL = POKEMONS.length;
}

async function getPokemonsInfos(pokeArray) {
  await Promise.all(
    pokeArray.map(async (pokemon) => {
      try {
        const RESPONSE = await fetch(pokemon.url);
        if (!RESPONSE.ok) throw new Error("Netzwerk Antwort Fehler!");
        const RESULT = await RESPONSE.json();
        saveDataToPokemon(pokemon, RESULT);
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
  const SEARCH_INPUT = getBoxId("search_input").value.trim().toLowerCase();
  if (SEARCH_INPUT.length < 3 && SEARCH_INPUT > 0) return;
  SEARCH_RESULTS = [];
  const POKEDEX_REF = getBoxId("pokedex");
  POKEDEX_REF.innerHTML = "";
  for (let i = 0; i < POKEMONS.length; i++) {
    const POKEMON = POKEMONS[i];
    const POKEMON_NAME = POKEMON.name;
    if (POKEMON_NAME.includes(SEARCH_INPUT)) {
      SEARCH_RESULTS.push(POKEMON);
      POKEDEX_REF.innerHTML += getPokedexCard(POKEMON_NAME, POKEMON.id, POKEMON.sprite_front, POKEMON.types);
    }
  }
  if (POKEDEX_REF.innerHTML == "") {
    POKEDEX_REF.innerHTML = nothingFoundTemplate();
  }
}

function openLoadingScreen() {
  if (!POKEMONS.length > 0) return;
  const DIALOG = getBoxId("loading_screen");
  DIALOG.showModal();
}

function closeLoadingScreen() {
  if (!POKEMONS.length > 0) return;
  const DIALOG = getBoxId("loading_screen");
  DIALOG.close();
}

function resetInput() {
  const SEARCH_INPUT = getBoxId("search_input");
  const POKEDEX = getBoxId("pokedex");
  SEARCH_INPUT.value = "";
  SEARCH_RESULTS = [];
  POKEDEX.innerHTML = "";
  renderAllPokemons();
}
