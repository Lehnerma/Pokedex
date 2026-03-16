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
  for (i = 0; i < pokemonTypes.length; i++)
    if (type[0] == pokemonTypes[i].value) {
      return pokemonTypes[i].gradient;
    }
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
