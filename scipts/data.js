const BASE_URL = "https://pokeapi.co/api/v2/";
let OFFSET_FOR_URL = 0;
let LOAD_LIMIT = 20;
let CURRENT_LENGTH_POKEMONS = 0;
const OFFSET_Poke = (beginn, limit) => `https://pokeapi.co/api/v2/pokemon?limit=${limit}&offset=${beginn}`;
let POKEMONS = [];

const pokemonTypes = [
  { name: "Normal", value: "normal", color: "#A8A77A", gradient: "linear-gradient(135deg, #A8A77A 0%, #7A7955 100%)" },
  { name: "Fire", value: "fire", color: "#EE8130", gradient: "linear-gradient(135deg, #F08030 0%, #C03028 100%)" },
  { name: "Water", value: "water", color: "#6390F0", gradient: "linear-gradient(135deg, #6390F0 0%, #3859A0 100%)" },
  { name: "Grass", value: "grass", color: "#7AC74C", gradient: "linear-gradient(135deg, #7AC74C 0%, #4E8234 100%)" },
  { name: "Electric", value: "electric", color: "#F7D02C", gradient: "linear-gradient(135deg, #F7D02C 0%, #B9A01B 100%)" },
  { name: "Ice", value: "ice", color: "#96D9D6", gradient: "linear-gradient(135deg, #98D8D8 0%, #6AB0B0 100%)" },
  { name: "Fighting", value: "fighting", color: "#C22E28", gradient: "linear-gradient(135deg, #C03028 0%, #7D1F1A 100%)" },
  { name: "Poison", value: "poison", color: "#A33EA1", gradient: "linear-gradient(135deg, #A040A0 0%, #682A68 100%)" },
  { name: "Ground", value: "ground", color: "#E2BF65", gradient: "linear-gradient(135deg, #E0C068 0%, #8E7A42 100%)" },
  { name: "Flying", value: "flying", color: "#A98FF3", gradient: "linear-gradient(135deg, #A890F0 0%, #705898 100%)" },
  { name: "Psychic", value: "psychic", color: "#F95587", gradient: "linear-gradient(135deg, #F85888 0%, #A13959 100%)" },
  { name: "Bug", value: "bug", color: "#A6B91A", gradient: "linear-gradient(135deg, #A8B820 0%, #6D7815 100%)" },
  { name: "Rock", value: "rock", color: "#B6A136", gradient: "linear-gradient(135deg, #B8A038 0%, #786824 100%)" },
  { name: "Ghost", value: "ghost", color: "#735797", gradient: "linear-gradient(135deg, #705898 0%, #483960 100%)" },
  { name: "Dragon", value: "dragon", color: "#6F35FC", gradient: "linear-gradient(135deg, #7038F8 0%, #4824A0 100%)" },
  { name: "Steel", value: "steel", color: "#B7B7CE", gradient: "linear-gradient(135deg, #B8B8D0 0%, #787887 100%)" },
  { name: "Dark", value: "dark", color: "#705746", gradient: "linear-gradient(135deg, #705848 0%, #48392F 100%)" },
  { name: "Fairy", value: "fairy", color: "#D685AD", gradient: "linear-gradient(135deg, #EE99AC 0%, #9B6470 100%)" },
];
