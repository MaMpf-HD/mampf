/**
 * Renders math in the given element using KaTeX.
 *
 * @param element The HTML element to render math in.
 */
// eslint-disable-next-line no-unused-vars
function renderMath(element) {
  renderMathInElement(element, {
    delimiters: [
      {
        left: "$$",
        right: "$$",
        display: true,
      },
      {
        left: "$",
        right: "$",
        display: false,
      },
      {
        left: "\\(",
        right: "\\)",
        display: false,
      },
      {
        left: "\\[",
        right: "\\]",
        display: true,
      },
    ],
    throwOnError: false,
  });
}
