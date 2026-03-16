function getPokedexCard(name, number, sprite_front, types) {
  return `
        <article class="pokedex-card" style="background: ${checkBgDex(types)} ;" data-id="${number}">
          <img src=${sprite_front} alt="sprite for ${name}" class="pokedex-sprite"/>
          <h6 class="pokedex-name">${capitalizeFirstLetter(name)}</h6>
          <p class="pokedex-number caption-sm">#${number}</p>
          <section class="pokedex-types" role="container for types">
            ${createTypes(types)}
          </section>
        </article>`;
}

function getStatsContainer() {
  return `
                  <section class="stats-container">
                  <div class="stat-container">
                    <label for="stat_hp" class="stat-title">HP</label>
                    <p class="stat-value">50</p>
                    <progress id="stat_hp" value="50" max="255" class="stat-progress"></progress>
                  </div>
                  <div class="stat-container">
                    <label for="stat_ang" class="stat-title">ANG</label>
                    <p class="stat-value">50</p>
                    <progress id="stat_ang" value="150" max="255" class="stat-progress"></progress>
                  </div>
                  <div class="stat-container">
                    <label for="stat_spAng" class="stat-title">SP ANG</label>
                    <p class="stat-value">50</p>
                    <progress id="stat_spAng" value="250" max="255" class="stat-progress"></progress>
                  </div>
                  <div class="stat-container">
                    <label for="stat_def" class="stat-title">DEF</label>
                    <p class="stat-value">50</p>
                    <progress id="stat_def" value="180" max="255" class="stat-progress"></progress>
                  </div>
                  <div class="stat-container">
                    <label for="stat_spDef" class="stat-title">SP DEF</label>
                    <p class="stat-value">50</p>
                    <progress id="stat_spDef" value="50" max="255" class="stat-progress"></progress>
                  </div>
                  <div class="stat-container">
                    <label for="stat_speed" class="stat-title">SPEED</label>
                    <p class="stat-value">50</p>
                    <progress id="stat_speed" value="50" max="255" class="stat-progress"></progress>
                  </div>
                </section>`;
}


