function getBoxId(id) {
  const BOX_ID = document.getElementById(id);
  return BOX_ID;
}

function capitalizeFirstLetter(val) {
  return String(val).charAt(0).toUpperCase() + String(val).slice(1);
}

function createTypes(types) {
  return types.map((type) => `<span class="type ${type}" role="img" aria-label="${type}"></span>`).join("");
}

function checkBgDex(type) {
  for (i = 0; i < POKEMON_TYPS.length; i++)
    if (type[0] == POKEMON_TYPS[i].value) {
      return POKEMON_TYPS[i].gradient;
    }
}

function renderData(data, boxID) {
  const REF = getBoxId(boxID);
  REF.innerHTML = "";
  REF.innerHTML = data;
}

function hgToKg(value) {
  const RESULT = (value * 0.1).toFixed(1);
  return Number(RESULT);
}

function ftToM(value) {
  const RESULT = (value / 10).toFixed(2);
  return Number(RESULT);
}
//===========================
//  Local Storage for testing.
// ==========================
function saveToLocal() {
  const data = JSON.stringify(POKEMONS);
  console.log(data);
  localStorage.setItem("pokemons", data);
}

function loadFromLocal() {
  const obj = JSON.parse(localStorage.getItem("pokemons")) ?? "null";
  POKEMONS = obj;
  showPokemons();
}

function loadCurrentTab() {
  const CURRENT_TAB = localStorage.getItem("current-tab");
  return CURRENT_TAB;
}
