// Libraries MaMpf used to load from a CDN as global scripts. The JS responses
// rendered by the server (*.coffee, *.js.erb) and some older scripts still
// call them as globals, so they are bundled here and put on window, before
// any other module of the entrypoint runs.
import katex from "katex";
import renderMathInElement from "katex/dist/contrib/auto-render";
import TomSelect from "tom-select";
import cytoscape from "cytoscape";
import nerdamer from "nerdamer/nerdamer.core.js";
import "nerdamer/Algebra.js";
// The prebuilt browser bundle: the package's main file pulls in postcss and
// other Node modules.
import sanitizeHtml from "sanitize-html/dist/sanitize-html.min.js";

Object.assign(window, {
  katex,
  renderMathInElement,
  TomSelect,
  cytoscape,
  nerdamer,
  sanitizeHtml,
});
