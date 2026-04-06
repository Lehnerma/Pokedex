function init() {
  initBtn();
  initCard();
}

/**
 * Initializes all buttons
 */
function initBtn() {
  const BALL_BTN = document.getElementById("ball_btn");
  const SEARCH = getBoxId("search_input");
  const SEARCH_BTN = getBoxId("search_btn");
  const RESET_SEARCH_BTN = getBoxId("reset_btn");
  BALL_BTN.addEventListener("click", () => openBall(BALL_BTN));
  SEARCH.addEventListener("change", searchPokemon);
  SEARCH_BTN.addEventListener("click", searchPokemon);
  RESET_SEARCH_BTN.addEventListener("click", resetInput);
}

/**
 * Render the new Pokémons with the load more button
 */
function renderPokemons() {
  let POKEDEX = getBoxId("pokedex");
  for (let i = CURRENT_LENGTH_POKEMONS; i < POKEMONS.length; i++) {
    POKEDEX.innerHTML += getPokedexCard(POKEMONS[i].name, POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
  }
}

/**
 * Render all Pokémons from the Array (POKEMONS)
 */
function renderAllPokemons() {
  let POKEDEX = getBoxId("pokedex");
  for (let i = 0; i < POKEMONS.length; i++) {
    POKEDEX.innerHTML += getPokedexCard(POKEMONS[i].name, POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
  }
}

/**
 * Adds the class 'open' to the body to geht the animation of the opening pokeball
 */
function addClassBody() {
  document.body.classList.add("open");
}

/**
 * 
 * @param {*} btn - to togggle the 'shake' animation with for opening the pokeball on the landing page 
 */
function openBall(btn) {
  btn.classList.add("shake");
  btn.disabled = true;
  getPokemons();
  setTimeout(() => {
    btn.classList.remove("shake");
    addClassBody();
  }, 1500);
}

/**
 * fetch the Pokemon list with the ID and the info link
 */
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
  saveToLocal();
  OFFSET_FOR_URL = POKEMONS.length;
}

/**
 * Fetch the information for the Pokémon that is needed to display the cards.
 * @param {Array} pokeArray ->  must be the array from the getPokemons() func - the array musst have the url for the Pokémon infos. 
 */
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

/**
 * Helper function for better, more readable code - saves the necessary information about the respective Pokemon
 * @param {*} pokemon -> Information about this Pokémon will be stored.
 * @param {*} data -> The information is stored from this data.
 */
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

/**
 * Pokémon that begin with or contain the letters in the search results.
 * @returns The Pokémons of the search.
 */
function searchPokemon() {
  const SEARCH_INPUT = getBoxId("search_input").value.trim().toLowerCase();
  if (SEARCH_INPUT.length < 3 && SEARCH_INPUT > 0) return;
  const POKEDEX_REF = getBoxId("pokedex");
  SEARCH_RESULTS = [];
  POKEDEX_REF.innerHTML = "";
  for (let i = 0; i < POKEMONS.length; i++) {
    const POKEMON = POKEMONS[i];
    if (POKEMON.name.includes(SEARCH_INPUT)) {
      SEARCH_RESULTS.push(POKEMON);
      POKEDEX_REF.innerHTML += getPokedexCard(POKEMON.name, POKEMON.id, POKEMON.sprite_front, POKEMON.types);
    }
  }
  if (POKEDEX_REF.innerHTML == "") {
    POKEDEX_REF.innerHTML = nothingFoundTemplate();
  }
}

/**
 * Opens the loading screen - if the fetching the api takes longer
 */
function openLoadingScreen() {
  if (!POKEMONS.length > 0) return;
  const DIALOG = getBoxId("loading_screen");
  DIALOG.showModal();
}

/**
 * Closes the loading screen
 */
async function closeLoadingScreen() {
  if (!POKEMONS.length > 0) return;
  const DIALOG = getBoxId("loading_screen");
  setTimeout(() => DIALOG.close(), 500);
}

/**
 * Resets the input for the search input
 */
function resetInput() {
  const SEARCH_INPUT = getBoxId("search_input");
  const POKEDEX = getBoxId("pokedex");
  SEARCH_INPUT.value = "";
  POKEDEX.innerHTML = "";
  SEARCH_RESULTS = [];
  renderAllPokemons();
}
