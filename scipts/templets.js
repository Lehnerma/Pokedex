function getDexPokemon(name, number, types) {
  // types must be an array?
  return `
        <article class="dex-poke">
        <img src="./bisasam.png" alt="Bisasam" class="dex-poke-sprit" />
        <div class="dex-poke-info">
          <p>#${number}</p>
          <h3>${name}</h3>
        </div>
        <div class="dex-poke-typs id="dex_poke_types">
  <img src="./.png" alt="${types[0]}" />
  <img src="./.png" alt="${types[1]}" />
        </div>
      </article>`;
}
