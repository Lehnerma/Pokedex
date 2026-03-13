function getPokedexCard(name, number, sprite_front, types) {
  return `
        <article class="pokedex-card" data-id="${number}">
          <img src=${sprite_front} alt="sprite for ${name}" class="pokedex-sprite"/>
          <h6 class="pokedex-name">${name}</h6>
          <p class="pokedex-number caption-sm">#${number}</p>
          <section class="pokedex-types" role="container for types">
            ${createTypes(types)}
          </section>
        </article>`;
}

function createTypes(types) {
  return types.map((type) => `<span class="type ${type}" role="img" aria-label="${type}"></span>`).join("");
}
