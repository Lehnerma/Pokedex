//base url erstellen
const BASE_URL = "https://pokeapi.co/api/v2/";
// width the number we can fetch a fix numb of poke
const OFFSET_Poke = (number) => `https://pokeapi.co/api/v2/pokemon?limit=${number}&offset=0`

// function for fetching
// loading spinner integretting
function init() {
  initBtn();
}

function initBtn() {
  const ballBtn = document.getElementById("ball_btn");
  ballBtn.addEventListener("click", () => openBall(ballBtn));
}

function addClassBody() {
  document.body.classList.add("open");
}

function openBall(btn) {
  btn.classList.add("shake");
  setTimeout(() => {
    btn.classList.remove("shake");
    addClassBody();
  }, 500);
}

