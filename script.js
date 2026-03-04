//base url erstellen
// url for offste
// function for fetching
// loading spinner integretting
function init() {
  initBtn();
}

function initBtn() {
  const ballBtn = document.getElementById("ball_btn");
  ballBtn.addEventListener("click", () => {
    // erst die shake bewegeung dann das öffnen.
    ballBtn.classList.add("shake");
    setTimeout(() => {
      ballBtn.classList.remove("shake");
      document.body.classList.add("open");
    }, 500);
  });
}
