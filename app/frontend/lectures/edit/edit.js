import { initMasonryGridSystem } from "~/js/masonry_grid";

const HOME_INTRO_TRIX_ID = "lecture-home-intro-trix";

const KATEX_DELIMITERS = [
  { left: "$$", right: "$$", display: true },
  { left: "$", right: "$", display: false },
  { left: "\\(", right: "\\)", display: false },
  { left: "\\[", right: "\\]", display: true },
];

function renderMathIn(element) {
  if (!element || typeof renderMathInElement !== "function") {
    return;
  }
  renderMathInElement(element, {
    delimiters: KATEX_DELIMITERS,
    throwOnError: false,
  });
}

function showHomeFormWarning() {
  $("#lecture-home-warning").show();
}

// Trix sits in KaTeX's `ignoredClasses` and shows the raw `$...$` source, hence
// the preview. It must not carry a `trix-content` class, or KaTeX skips it too.
function initHomeIntroPreview() {
  const editor = document.getElementById(HOME_INTRO_TRIX_ID);
  if (!editor) {
    return;
  }

  const preview = document.getElementById(editor.dataset.preview);
  if (!preview) {
    return;
  }

  const update = () => {
    preview.innerHTML = editor.innerHTML;
    renderMathIn(preview);
  };

  update();
  editor.addEventListener("trix-initialize", update);

  editor.addEventListener("trix-change", () => {
    update();
    showHomeFormWarning();
  });
}

function initHomeFormWarning() {
  $("#lecture-home-form :input").on("change", showHomeFormWarning);
  $("#cancel-lecture-home").on("click", () => location.reload());
}

// Hiding the toolbar button (lectures.scss) leaves drag & drop and paste open.
document.addEventListener("trix-file-accept", (event) => {
  if (event.target?.id === HOME_INTRO_TRIX_ID) {
    event.preventDefault();
  }
});

$(() => {
  initBootstrapPopovers();

  $("#lecture-nav-content").on("shown.bs.tab", () => {
    initMasonryGridSystem();
  });
});

$(document).on("turbo:load", () => {
  initHomeIntroPreview();
  initHomeFormWarning();
});
