const BASE_URL = "https://pokeapi.co/api/v2/";
let OFFSET_FOR_URL = 0;
let LOAD_LIMIT = 20;
const OFFSET_Poke = (beginn, limit) => `https://pokeapi.co/api/v2/pokemon?limit=${limit}&offset=${beginn}`;
let POKEMONS = [];

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
  }, 600); // is also the loading screen for the first fetch
}

// Get Pokemon Infos for the Dex and the Cards
async function getPokemon() {
  try {
    const response = await fetch(OFFSET_Poke(OFFSET_FOR_URL, LOAD_LIMIT));
    const result = await response.json();
    POKEMONS.push(...result.results); // ... spread operator - the values will directly push into the array
    await getPokemonInfos(POKEMONS);
    showPokemon();
  } catch (er) {
    console.error(er);
  }
}

async function getPokemonInfos(pokeArray) {
  for (const pokemon of pokeArray) {
    const response = await fetch(pokemon.url);
    const result = await response.json();
    (pokemon.weight = result.weight), //
      (pokemon.height = result.height), //
      (pokemon.id = result.id), //
      (pokemon.sprite_front = result.sprites.front_default), //
      (pokemon.sprite_back = result.sprites.back_default), //
      (pokemon.types = getTypes(result.types)), //
      (pokemon.cries = result.cries.latest),
      (pokemon.stats = saveStats(result.stats));
  }
}

function saveStats(statsArray) {
  let baseStats = [];
  statsArray.forEach((element) => {
    baseStats.push({
      name: element.stat.name,
      value: element.base_stat,
    });
  });
  return baseStats;
}

function getTypes(typeArray) {
  let poketype = [];
  typeArray.forEach((types) => {
    poketype.push(types.type.name);
  });
  return poketype;
}

function showPokemon() {
  let pokedex = document.getElementById("pokedex");
  console.log(!POKEMONS.length);
  const index = !POKEMONS.length ? 0 : POKEMONS.length - 20;
  for (let i = index; i < POKEMONS.length; i++) {
    pokedex.innerHTML += getPokedexCard(capitalizeFirstLetter(POKEMONS[i].name), POKEMONS[i].id, POKEMONS[i].sprite_front, POKEMONS[i].types);
  }
}

function capitalizeFirstLetter(val) {
  return String(val).charAt(0).toUpperCase() + String(val).slice(1);
}

// Testing Section
function test() {
  const loadBtn = document.getElementById("load_btn");
  loadBtn.addEventListener("click", () => getPokemon());
  document.getElementById("pokedex").addEventListener("click", handelClick);
}

function handelClick(event) {
  const target = event.target.closest("[data-id]");
  console.log(target);
}

function loadNewPokemons() {
  OFFSET_FOR_URL = POKEMONS.length;
  getPokemon();
}
