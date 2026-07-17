export const KATEX_DELIMITERS = [
  { left: "$$", right: "$$", display: true },
  { left: "$", right: "$", display: false },
  { left: "\\(", right: "\\)", display: false },
  { left: "\\[", right: "\\]", display: true },
];

// A $$…$$ display-math block. Written as an "unrolled loop" (each iteration
// consumes a single `$`) so it matches in linear time — a lazy `[\s\S]*?`
// searching for a closing `$$` that may be absent backtracks catastrophically.
const DISPLAY_MATH = /\$\$([^$]*(?:\$(?!\$)[^$]*)*)\$\$/g;
// A run of Trix line breaks (with surrounding whitespace) inside such a block.
const DISPLAY_MATH_BREAK_RUN = /(?:\s*<br\s*\/?>\s*)+/gi;

// Trix splits display math across `<br>`s, which stops KaTeX from pairing the
// `$$` delimiters. Collapse those breaks to newlines within each block. Run per
// block on the bounded content, never as one regex over the whole HTML — the
// break run alone has no failing tail, so it stays linear.
export function normalizeDisplayMathLineBreaks(html) {
  return html.replace(DISPLAY_MATH, (_match, content) => (
    `$$${content.replace(DISPLAY_MATH_BREAK_RUN, "\n")}$$`
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
