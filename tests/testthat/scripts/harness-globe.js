// Harness de teste do cliente do globo (painel-globe.js) sem navegador:
// DOM falso + canvas 2d no-op, controlador real. Rodado por
// test-painel-globe-cliente.R com system2("node"); pula sem node.
//
// Uso: node harness-globe.js <forma>
//   forma = "objeto"  -> geojson como objeto (transporte real do Shiny,
//                        json_verbatim=TRUE na classe "json" do jsonlite)
//   forma = "string"  -> geojson como string escapada (forma historica)
const fs = require("fs");
const path = require("path");

const forma = process.argv[2] === "objeto" ? "objeto" : "string";

let rafQueue = [];
const calls = { fill: 0 };

function makeCtx() {
  const grad = { addColorStop: function () {} };
  return {
    beginPath: function () {}, moveTo: function () {}, lineTo: function () {},
    closePath: function () {}, arc: function () {},
    fill: function () { calls.fill++; }, stroke: function () {},
    clearRect: function () {}, save: function () {},
    restore: function () {}, setTransform: function () {},
    createRadialGradient: function () { return grad; }
  };
}

function makeEl(tag) {
  const el = {
    tagName: tag, children: [], style: {}, dataset: {}, hidden: false,
    textContent: "", width: 0, height: 0,
    classList: { add: function () {}, contains: function () { return false; } },
    setAttribute: function () {}, getAttribute: function () { return null; },
    addEventListener: function () {}, removeEventListener: function () {},
    appendChild: function (c) { el.children.push(c); c.parentNode = el; return c; },
    replaceChildren: function () { el.children = []; },
    getBoundingClientRect: function () {
      return { width: 400, height: 400, left: 0, top: 0 };
    },
    querySelector: function () { return null; },
    isConnected: true, offsetWidth: 0, offsetHeight: 0
  };
  if (tag === "canvas") {
    el.getContext = function () { return makeCtx(); };
    el.setPointerCapture = function () {};
    el.hasPointerCapture = function () { return true; };
    el.releasePointerCapture = function () {};
  }
  return el;
}

const host = makeEl("div");
host.className = "painel-globo-host";
host.id = "regiao-panel_globe_1-globo";

const documentStub = {
  readyState: "complete",
  documentElement: makeEl("html"),
  body: makeEl("body"),
  querySelector: function (sel) {
    return sel === ".painel-globo-host" ? host : null;
  },
  getElementById: function (id) { return id === host.id ? host : null; },
  createElement: function (tag) { return makeEl(tag); },
  addEventListener: function () {}
};
class MutationObserverStub { constructor() {} observe() {} disconnect() {} }

globalThis.window = globalThis;
window.document = documentStub;
window.getComputedStyle = function () {
  return { getPropertyValue: function () { return ""; } };
};
window.matchMedia = function () { return { matches: true }; };
window.devicePixelRatio = 1;
window.MutationObserver = MutationObserverStub;
window.requestAnimationFrame = function (cb) { rafQueue.push(cb); return rafQueue.length; };
window.cancelAnimationFrame = function () {};
window.fetch = function () { return Promise.reject(new Error("sem rede")); };
window.addEventListener = function () {};

function pump(limit) {
  let n = 0;
  while (rafQueue.length && n < limit) {
    const q = rafQueue; rafQueue = [];
    q.forEach(function (cb) { cb(0); });
    n++;
  }
}

const raiz = require("path");
const base = raiz.join(raiz.dirname(__filename), "..", "..", "..");
[raiz.join(base, "inst", "painel", "painel-geo.js"),
 raiz.join(base, "inst", "painel", "painel-globe.js")
].forEach(function (p) { new Function(fs.readFileSync(p, "utf8"))(); });

// Mensagem minima no formato do observe de mod_panel_globe.R: um quadrado
const quadrado = JSON.stringify({
  type: "FeatureCollection",
  features: [{
    type: "Feature",
    properties: { code: "1", label: "a" },
    geometry: { type: "Polygon",
      coordinates: [[[0, 0], [1, 0], [1, 1], [0, 1], [0, 0]]] }
  }]
});
const msg = {
  hostId: host.id,
  inputId: "regiao-panel_globe_1-clique",
  readyId: "regiao-panel_globe_1-pronto",
  modo: "nivel",
  nivel: "subdistrito",
  locais: [{ code: "1", label: "a" }],
  disponiveis: ["1"],
  selected: "1",
  destaque: "",
  contexto: "",
  geojson: forma === "objeto" ? JSON.parse(quadrado) : quadrado
};

try {
  window.PainelGlobo.update(msg);
  pump(20);
  const ok = host.dataset.ready === "true" &&
    host.dataset.featureCount === "1" && calls.fill > 0;
  console.log((ok ? "OK" : "FALHOU") + " " + forma +
    " ready=" + host.dataset.ready +
    " features=" + host.dataset.featureCount +
    " selected=" + JSON.stringify(host.dataset.selected));
  process.exit(ok ? 0 : 1);
} catch (error) {
  console.log("FALHOU " + forma + " excecao: " +
    (error && error.stack ? error.stack : String(error)));
  process.exit(1);
}
