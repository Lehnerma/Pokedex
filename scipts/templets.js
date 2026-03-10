function getPokedexCard(name, number, sprite_front, types) {
  // types must be an array? get a function or template to get the types
  return `
        <article class="pokedex-card">
          <img src=${sprite_front} alt="sprite for ${name}" class="pokedex-sprite"/>
          <h6 class="pokedex-name">${name}</h6>
          <p class="pokedex-number caption-sm">#${number}</p>
          <section class="pokedex-types" role="container for types">
            <span class="type ${types[0]}" role="type img"></span>
            <span class="type ${types[1]}" role="type img"></span>
          </section>
        </article>`;
}
// testing these function
function typesTemplate(types) {
  for (let i = 0; i < types.length; i++) {
    return `<span class="type ${types[i]}" role="type img"></span>`;
  }
}
