
/**
 * Shorthand-Function to geht the Code cleaner
 * @param {string} id ->  The ID of the Element in the HTML/Templet to worke with.
 * @returns -> the full HTML Box.
 */
function getBoxId(id) {
  const BOX_ID = document.getElementById(id);
  return BOX_ID;
}

/**
 * The get the first letter capitalize.
 * @param {string} val -> String where we capitalize the first letter
 * @returns {string} -> The string (=val) with the first letter capitalize
 */
function capitalizeFirstLetter(val) {
  return String(val).charAt(0).toUpperCase() + String(val).slice(1);
}

/**
 * To creat the type img for each Pokémon.
 * @param {Array} types -> The array of the types from the PokéAPI
 * @returns {TemplateStringsArray} -> each templet for every type in the array
 */
function createTypes(types) {
  return types.map((type) => `<span class="type ${type}" role="img" aria-label="${type}"></span>`).join("");
}

/**
 * To geht the gradient for the type of the Pokémon
 * @param {string} type -> the name of the type
 * @returns {gradient} -> the gradient code from the data.js file
 */
function getTypeGradient(type) {
  const TYPE = POKEMON_TYPS.find((el) => type[0] == el.value);
  return TYPE.gradient;
}

/**
 * Shorthand to reder the Datas into the Pokémon Cards in the main view.
 * @param {*} data -> the data with we want to display in the box in the HTML
 * @param {*} boxID -> the box in the HTML witch we want to display in it.
 */
function renderData(data, boxID) {
  const REF = getBoxId(boxID);
  REF.innerHTML = "";
  REF.innerHTML = data;
}

/**
 * Function to convert form hg to kg.
* @param {number} value - The weight in hectograms (from the PokéAPI).
 * @returns {number} The weight converted to kilograms.
 */
function hgToKg(value) {
  const RESULT = (value * 0.1).toFixed(1);
  return Number(RESULT);
}

/**
 * Function to convert feet to meter.
 * @param {number} value -> The height in feet (from the PokéAPI)
 * @returns {number} The height converted to meters.
 */
function ftToM(value) {
  const RESULT = (value / 10).toFixed(2);
  return Number(RESULT);
}

function loadCurrentTab() {
  const CURRENT_TAB = localStorage.getItem("current-tab");
  return CURRENT_TAB;
}

function loadFromLocal() {
  const obj = JSON.parse(localStorage.getItem("pokemons")) ?? "null";
  POKEMONS = obj;
  showPokemons();
}

function saveLocal() {
  if (confirm("Would you store the array local?")) {
    saveToLocal();
  } else {
    return;
  }
}

function saveToLocal() {
  const data = JSON.stringify(POKEMONS);
  console.log(data);
  localStorage.setItem("pokemons", data);
}