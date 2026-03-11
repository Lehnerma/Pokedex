const BASE_URL = "https://pokeapi.co/api/v2/";

const OFFSET_Poke = (number) => `https://pokeapi.co/api/v2/pokemon?limit=${number}&offset=0`;
let POKEMON = [];

function init() {
  initBtn();
  test();
}

function initBtn() {
  const ballBtn = document.getElementById("ball_btn");
  ballBtn.addEventListener("click", () => openBall(ballBtn));
}

// this function is only for programmin and the testing buttons
function test() {
  const loadBtn = document.getElementById("load_btn");
  loadBtn.addEventListener("click", () => getPokemon(9));
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
  }, 500);
}

//---- Pokemon + Infos -----

async function getPokemon(number) {
  try {
    const response = await fetch(OFFSET_Poke(number));
    const result = await response.json();
    POKEMON.push(...result.results); // ... spread operator - the values will directly push into the array
    savePokemonInfos(POKEMON);
  } catch (er) {
    console.error(er);
  }
}

// save the infos whitch i need for the dex and the infocard
async function savePokemonInfos(pokeArray) {
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
// save stats
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

// get only the types name - the return is a array for looping
function getTypes(typeArray) {
  let poketype = [];
  typeArray.forEach((types) => {
    poketype.push(types.type.name);
  });
  return poketype;
}
function showPokemon() {
  let pokedex = document.getElementById("pokedex");
  pokedex.innerHTML = "";
  POKEMON.forEach((pokemon) => {
    pokedex.innerHTML += getPokedexCard(pokemon.name, pokemon.id, pokemon.sprite_front, pokemon.types);
  });
}
