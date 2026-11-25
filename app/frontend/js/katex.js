import { default as katexRenderMathInElement } from "katex/dist/contrib/auto-render";

// TODO: import CSS properly once we completely removed Katex from _head.html.erb
// import "katex/dist/katex.min.css";

$(document).on("turbo:load", function () {
  katexRenderMathInElement(document.body, {
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
    // no-katex: text shown verbatim, e.g. the site-wide announcements
    ignoredClasses: ["trix-content", "form-control", "no-katex"],
    throwOnError: false,
  },
  );
});
