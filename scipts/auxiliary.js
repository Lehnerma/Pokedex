function getBoxId(id) {
  const BOX_ID = document.getElementById(id);
  return BOX_ID;
}

function capitalizeFirstLetter(val) {
  return String(val).charAt(0).toUpperCase() + String(val).slice(1);
}
