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