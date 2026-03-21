function getPokedexCard(name, number, sprite_front, types) {
  return `
<article class="pokedex-card" style="background: ${getTypeGradient(types)} ;" data-id="${number}">
  <img src=${sprite_front} alt="sprite for ${name}" class="pokedex-sprite"/>
  <h6 class="pokedex-name">${capitalizeFirstLetter(name)}</h6>
  <p class="pokedex-number caption-sm">#${number}</p>
  <section class="pokedex-types" role="container for types">
    ${createTypes(types)}
  </section>
</article>`;
}

function getEvolutionTemplate(name, src) {
  return `
<div class="evolution-card">
  <img src=${src} alt="${name}" class="evolution-img" />
</div>
  `;
}

function statTemplate(stat, value) {
  return `
<div class="stat-container">
  <label for="stat_${stat}" class="stat-title">${capitalizeFirstLetter(stat)}</label>
  <p class="stat-value" id="stat_${stat}_value">${value}</p>
  <progress id="stat_${stat}" value="${value}" max="255" class="stat-progress"></progress>
</div>`;
}

function spritTemplate() {
  return `
<img src="/assets/img/654.png" alt="sprite-front pokemon-name" class="sprite-front" />
<img src="./assets/img/type_modern/Water.svg" alt="type" class="type" />`;
}

function typeTemplet(type, typeSrc) {
  return `
<img src="${typeSrc}" alt="${type}" class="type" />`;
}

function nothingFoundTemplate() {
  return `
<div class="nothing-found-container">
  <p class="title">Nothing found with this input. Go and catch them all!</p>
  <img src="./assets/img/knofensa.svg" alt="Knofensa" class="knofensa" />
</div>`;
}
