function init() {
  initBtn();
  test();

  loadContent(CURRENT_TAB);
}

function initBtn() {
  const BALL_BTN = document.getElementById("ball_btn");
  const POKEDEX = document.getElementById("pokedex");

  BALL_BTN.addEventListener("click", () => openBall(BALL_BTN));
  POKEDEX.addEventListener("click", openPokemonCard);
}

//===========================//
//  Landing page
// ==========================//
function addClassBody() {
  document.body.classList.add("open");
}

function openBall(btn) {
  btn.classList.add("shake");
  getPokemons();
  setTimeout(() => {
    btn.classList.remove("shake");
    addClassBody();
  }, 1000); // is also the loading screen for the first fetch
}
//===========================
//  get pokemon datas
// ==========================
async function getPokemons() {
  CURRENT_LENGTH_POKEMONS = POKEMONS.length;
  openLoadingScreen();
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
  let pokedex = getBoxId("pokedex");
  for (let i = CURRENT_LENGTH_POKEMONS; i < POKEMONS.length; i++) {
    pokedex.innerHTML += getPokedexCard(POKEMONS[i].name, POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
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
//===========================
//  testing & creating
// ==========================
function test() {
  const CARD_DIALOG = getBoxId("pokecard_dialog");
  CARD_DIALOG.addEventListener("click", pokecardClose);

  loadFromLocal();

  const searchInput = getBoxId("search_input");
  searchInput.addEventListener("input", searchPokemon);
}


//===========================
//  Dialog
// ==========================

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

function openPokeCard() {
  document.body.style.overflow = "hidden";
  const dialog = getBoxId("pokecard_dialog");
  dialog.showModal();
}
function closePokeCard() {
  document.body.style.overflow = "";
  const dialog = getBoxId("pokecard_dialog");
  dialog.close();
}

function pokecardClose(event) {
  let dialogRef = getBoxId("pokecard_dialog");
  if (event.target == dialogRef) {
    closePokeCard();
  }
}

//=============
//load cards
//=============

function openPokemonCard(event) {
  const ID = event.target.closest("[data-id]").dataset.id;
  const POKEMON = getPokemonInfos(ID);
  renderCard(POKEMON);
  openPokeCard();
}

function renderCard(pokemon) {
  renderBaseData(pokemon);
  renderStatsContent(pokemon);
  renderSprites(pokemon);
}

function renderBaseData(pokemon) {
  const NAME = capitalizeFirstLetter(pokemon.name);
  const NUMBER = `<b>#${pokemon.id}</b>`;
  const WEIGHT = `<b>WT.</b> ${hgToKg(pokemon.weight)}kg`;
  const HEIGHT = `<b>HT.</b> ${ftToM(pokemon.height)}m`;
  renderData(NAME, "card_name");
  renderData(NUMBER, "number");
  renderData(WEIGHT, "weight");
  renderData(HEIGHT, "height");
}

function renderStatsContent(pokemon) {
  const STATS_REF = getBoxId("stats_container");
  STATS_REF.innerHTML = "";
  for (let i = 0; i < pokemon.stats.length; i++) {
    STATS_REF.innerHTML += statTemplate(pokemon.stats[i].name, pokemon.stats[i].value);
  }
}

function renderSprites(pokemon) {
  renderFrontSprite(pokemon);
  renderBackSprite(pokemon);
  // renderType(pokemon);
}

function renderFrontSprite(pokemon) {
  const SPRITE_FRONT_SRC = pokemon.sprite_front;
  const SPRITE_REF = getBoxId("sprite_front");
  SPRITE_REF.src = SPRITE_FRONT_SRC;
  SPRITE_REF.alt = `sprite front ${pokemon.name}`;
}

function renderBackSprite(pokemon) {
  const SPRITE_BACK_SRC = pokemon.sprite_back;
  const SPRITE_REF = getBoxId("sprite_back");
  SPRITE_REF.src = SPRITE_BACK_SRC;
  SPRITE_REF.alt = `sprite back ${pokemon.name}`;
}

// function renderType(pokemon){
//   const TYPE = pokemon.types[0];
//   const TYPE_REF = getBoxId("type_modern")
//   const test = POKEMON_TYPES.find((element) => TYPE == element.value)
//   console.log(test);
  
// }

function getPokemonInfos(id) {
  if (id > POKEMONS.length) {
    id = 1;
  }
  if (id <= 0) {
    id = POKEMONS.length;
  }
  return POKEMONS.find((element) => element.id == id);
}

//=============
//Cards
//=============

function loadContent(tab) {
  localStorage.setItem("current-tab", tab);
  hideActivNav();
  hideContent();
  showActivNav();
  showActivContent();
}

function hideContent() {
  const CONTENTS = document.querySelectorAll(".content");
  CONTENTS.forEach((element) => {
    element.classList.add("d-none");
  });
}

function showActivContent() {
  hideContent();
  const CURRENT_TAB = loadCurrentTab();
  const CURRENT_CONTENT = document.getElementById(`${CURRENT_TAB}_container`);
  CURRENT_CONTENT.classList.remove("d-none");
}

function showActivNav() {
  const NAV = document.getElementById(loadCurrentTab());
  NAV.classList.add("activ");
}

function hideActivNav() {
  const NAV = document.querySelectorAll(".tab");
  NAV.forEach((element) => {
    element.classList.remove("activ");
  });
}
