async function fetchURL(url) {
  const requestedURL = await fetch(url);
  return requestedURL;
}

async function chageDataToJson(data) {
  const dataToJson = await data.json();
  return dataToJson;
}

function getBoxId(id) {
  const BOX_ID = document.getElementById(id);
  return BOX_ID;
}
