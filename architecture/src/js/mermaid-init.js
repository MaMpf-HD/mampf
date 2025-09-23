/* Mermaid bootstrap: assumes local mermaid.min.js already loaded via additional-js. */
(function () {
  if (window.__MERMAID_INIT__) return;
  window.__MERMAID_INIT__ = true;

  function init() {
    if (typeof mermaid === "undefined") {
      console.warn("Mermaid library not found (expected js/mermaid.min.js).");
      return;
    }
    mermaid.initialize({
      startOnLoad: true,
      securityLevel: "strict", // set to 'loose' if embedding inline HTML in diagrams
      theme: (window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches) ? "dark" : "default",
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  }
  else {
    init();
  }
})();
