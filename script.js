//base url erstellen
// url for offste
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
