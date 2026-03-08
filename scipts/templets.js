function getPokedexCard(name, number, types) {
  // types must be an array? get a function or template to get the types
  return `
        <article class="pokedex-card">
          <img src="./assets/img/balbasaur.png" alt="sprite for ${name}" class="pokedex-sprite"/>
          <h6 class="pokedex-name">${name}</h6>
          <p class="pokedex-number caption-sm">#${number}</p>
          <section class="pokedex-types" role="container for types">
            <span class="type fire" role="type img"></span>
            <span class="type grass" role="type img"></span>
          </section>
        </article>`;
}
