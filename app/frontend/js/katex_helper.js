export const KATEX_DELIMITERS = [
  { left: "$$", right: "$$", display: true },
  { left: "$", right: "$", display: false },
  { left: "\\(", right: "\\)", display: false },
  { left: "\\[", right: "\\]", display: true },
];

// Matches Trix display math where line breaks split `$$`, content, and `$$`.
const TRIX_DISPLAY_MATH_WITH_BREAKS
  = /\$\$(?:\s*<br\s*\/?>\s*)+([\s\S]*?)(?:\s*<br\s*\/?>\s*)+\$\$/gi;

export function normalizeDisplayMathLineBreaks(html) {
  return html.replace(TRIX_DISPLAY_MATH_WITH_BREAKS, (_match, content) => (
    `$$\n${content.replace(/<br\s*\/?>/gi, "\n")}\n$$`
  ));
}

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
