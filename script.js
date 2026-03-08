//base url erstellen
const BASE_URL = "https://pokeapi.co/api/v2/";
// width the number we can fetch a fix numb of poke
const OFFSET_Poke = (number) => `https://pokeapi.co/api/v2/pokemon?limit=${number}&offset=0`;
let POKEMON = [];
// function for fetching
// loading spinner integretting
function init() {
  initBtn();
  test();
}

function initBtn() {
  const ballBtn = document.getElementById("ball_btn");
  ballBtn.addEventListener("click", () => openBall(ballBtn));
}

function test() {
  const loadBtn = document.getElementById("load_btn");
  loadBtn.addEventListener("click", () => getPokemon(15));

  const dataBtn = document.getElementById("pokedata_btn");
  dataBtn.addEventListener("click", () => getPokemonInfo("https://pokeapi.co/api/v2/pokemon/1"));
}

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

async function getPokemon(number) {
  try {
    const response = await fetch(OFFSET_Poke(number));
    const result = await response.json();
    POKEMON.push(result); // ... spread operator - the values will directly push into the array
    // showPokemon();
    console.log(result.results);
  } catch (er) {
    console.error("the error is: ", er);
  }
}

async function getPokemonInfo(url) {
  try {
    const response = await fetch(url);
    const result = await response.json();
    console.log(result);
  } catch (er) {
    console.error("Dex-Info Error: ", er);
  }
}

function showPokemon() {
  let pokedex = document.getElementById("pokedex");
  pokedex.innerHTML = "";
  POKEMON.forEach((pokemon) => {
    pokedex.innerHTML += getPokedexCard(pokemon.name, 404);
    console.log(pokemon.name);
  });
}
