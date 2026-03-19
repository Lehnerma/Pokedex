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

function getTypeGradient(type) {
  const TYPE = POKEMON_TYPS.find((el) => type[0] == el.value);
  return TYPE.gradient;
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

function saveLocal() {
  if (confirm("Would you store the array local?")) {
    saveToLocal();
  } else {
    return;
  }
}
