window.addEventListener("load", () => {
  const ggbElement = document.getElementById("ggb-element");
  const filename = ggbElement.dataset.filename;
  const appName = ggbElement.dataset.type;
  const description = document.getElementById("geogebraDescription");

  renderMathInElement(description, {
    delimiters: [
      { left: "$$", right: "$$", display: true },
      { left: "$", right: "$", display: false },
      { left: "\\(", right: "\\)", display: false },
      { left: "\\[", right: "\\]", display: true },
    ],
    ignoredClasses: ["trix-content"],
    throwOnError: false,
  });

  const ggbApp = new GGBApplet({
    "appName": appName,
    "width": 500,
    "height": 700,
    "showToolBar": false,
    "showAlgebraInput": true,
    "showMenuBar": false,
    "filename": filename,
  }, true);

  ggbApp.inject("ggb-element");
});
