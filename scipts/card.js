function initCard() {
  const POKEDEX = document.getElementById("pokedex");
  POKEDEX.addEventListener("click", openPokemonCard);
  const CARD_DIALOG = getBoxId("pokecard_dialog");
  CARD_DIALOG.addEventListener("click", pokecardClose);

  loadContent(CURRENT_TAB);
}

function openPokeCard() {
  document.body.style.overflow = "hidden";
  const dialog = getBoxId("pokecard_dialog");
  dialog.showModal();
}

function pokecardClose(event) {
  let dialogRef = getBoxId("pokecard_dialog");
  if (event.target == dialogRef) {
    closePokeCard();
  }
}

function closePokeCard() {
  document.body.style.overflow = "";
  const dialog = getBoxId("pokecard_dialog");
  dialog.close();
}

//=============
//load cards data
//=============

function openPokemonCard(event) {
  const ID = event.target.closest("[data-id]").dataset.id;
  renderPokemonCard(ID);
}

async function renderPokemonCard(id) {
  const POKEMON = getPokemonFromArray(id);
  openLoadingScreen();
  await loadSpeciesData(id);
  await loadEvolutionChain(id);
  renderDatas(POKEMON);
  openPokeCard();
  nextCardBtn(POKEMON);
  closeLoadingScreen();
}

function renderDatas(pokemon) {
  renderBaseData(pokemon);
  renderStatsContent(pokemon);
  renderSprites(pokemon);
  renderText(pokemon);
  renderEvolutionImg(pokemon);
}

function nextCardBtn(pokemon) {
  let CURRENT_ID = pokemon.id;
  const BTN_LEFT = getBoxId("left");
  const BTN_RIGHT = getBoxId("right");
  BTN_LEFT.addEventListener("click", () => renderPokemonCard(checkId(--CURRENT_ID)));
  BTN_RIGHT.addEventListener("click", () => renderPokemonCard(checkId(++CURRENT_ID)));
}

function checkId(cur_id) {
  let NEXT_ID = cur_id;
  if (cur_id > POKEMONS.length) {
    NEXT_ID = 1;
  }
  if (cur_id == 0) {
    NEXT_ID = POKEMONS.length;
  }
  return NEXT_ID;
}

function getPokemonFromArray(id) {
  return POKEMONS.find((element) => element.id == id);
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
  renderType(pokemon);
  renderBgCard(pokemon);
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

function renderType(pokemon) {
  const TYPE_REF = getBoxId("type_modern");
  const TYPE = POKEMON_TYPS.find((element) => pokemon.types[0] == element.value);
  TYPE_REF.src = TYPE.imgSrc;
  TYPE_REF.alt = `type ${TYPE.value}`;
}

function renderBgCard(pokemon) {
  const POKEMON_TYPE = pokemon.types;
  const BG_REF = getBoxId("type_bg");
  const GRADIENT = getTypeGradient(POKEMON_TYPE);
  BG_REF.style.background = GRADIENT;
}

function renderText(pokemon) {
  const TEXT = pokemon.species_data.text;
  renderData(TEXT, "pokedex_info");
}

function renderEvolutionImg(pokemon) {
  const EVOLUTION_NAMES = pokemon.evolution_chain.names;
  const EVOLUTION_CONTAINER = getBoxId("evolution_container");
  EVOLUTION_CONTAINER.innerHTML = "";
  EVOLUTION_NAMES.forEach((name) => {
    const DATA = POKEMONS.find((poke) => poke.name == name);
    if (!DATA) return;
    EVOLUTION_CONTAINER.innerHTML += getEvolutionTemplate(capitalizeFirstLetter(DATA.name), DATA.sprite_front);
  });
}
//========
//load evo, info
//========
async function loadSpeciesData(id) {
  const ALL_BTN = document.querySelectorAll("button");
  ALL_BTN.forEach((btn) => (btn.disabled = true));
  const POKEMON = POKEMONS.find((poke) => poke.id == id);
  checkPokemonSpecies(POKEMON, id);
  try {
    const RESPONSE = await fetch(SPECIES_URL(id));
    const RESULT = await RESPONSE.json();
    saveSpeciesData(POKEMON, RESULT);
  } catch (error) {
    console.error(error);
  } finally {
    ALL_BTN.forEach((btn) => (btn.disabled = false));
  }
}

function checkPokemonSpecies(pokemon, id) {
  if (!pokemon) {
    console.error(`Pokemon #${id} fehler`);
    return;
  }
  if (pokemon.species_data) return;
}

function saveSpeciesData(pokemon, data) {
  pokemon.evolution_chain = data.evolution_chain;
  pokemon.species_data = {
    name: data.name,
    text: data.flavor_text_entries[0].flavor_text,
  };
}

async function loadEvolutionChain(id) {
  const POKEMON = POKEMONS.find((poke) => poke.id == id);
  const URL = POKEMON.evolution_chain.url;
  try {
    const RESPONSE = await fetch(URL);
    const RESULT = await RESPONSE.json();
    POKEMON.evolution_chain.names = getAllEvolutionNames(RESULT.chain);
  } catch (error) {
    console.error(error);
  }
}
// rekursive function
function getAllEvolutionNames(chain, namesArray = []) {
  namesArray.push(chain.species.name);

  chain.evolves_to.forEach((nextStep) => {
    getAllEvolutionNames(nextStep, namesArray);
  });

  return [...new Set(namesArray)];
}

//=============
//cards - content tabs
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
