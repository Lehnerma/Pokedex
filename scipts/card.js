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
//load cards
//=============

function openPokemonCard(event) {
  const ID = event.target.closest("[data-id]").dataset.id;
  const POKEMON = getPokemonInfos(ID);
  renderCard(POKEMON);
  openPokeCard();
  openLoadingScreen();
  loadSpeciesData(ID);
  closeLoadingScreen();
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
