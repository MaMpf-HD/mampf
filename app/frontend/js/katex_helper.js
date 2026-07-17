export const KATEX_DELIMITERS = [
  { left: "$$", right: "$$", display: true },
  { left: "$", right: "$", display: false },
  { left: "\\(", right: "\\)", display: false },
  { left: "\\[", right: "\\]", display: true },
];

export function renderMathIn(element, options = {}) {
  if (!element || typeof renderMathInElement !== "function") {
    return;
  }

  renderMathInElement(element, {
    delimiters: KATEX_DELIMITERS,
    throwOnError: false,
    ...options,
  });
}
