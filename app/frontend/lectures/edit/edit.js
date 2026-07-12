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

/**
 * Live preview for the lecture home intro.
 *
 * Trix sits in KaTeX's `ignoredClasses`, so the editor itself shows the raw
 * `$...$` source. Without this preview the teacher would write formulas blind.
 * The preview box deliberately carries no `trix-content` class, so it renders
 * math exactly the way the public home page does.
 */
function showHomeFormWarning() {
  $("#lecture-home-warning").show();
}

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

  // A real edit: refresh the preview and reveal the save button. Trix loading
  // the stored content does not fire this — the same assumption the
  // organizational form makes for #lecture-concept-trix.
  editor.addEventListener("trix-change", () => {
    update();
    showHomeFormWarning();
  });
}

/**
 * Reveal the unsaved-changes warning (which also carries the save button) as
 * soon as anything in the home form changes: the PDF field or the bin toggle.
 * The Trix editor is wired separately above. Mirrors the organizational form.
 */
function initHomeFormWarning() {
  $("#lecture-home-form :input").on("change", showHomeFormWarning);
  $("#cancel-lecture-home").on("click", () => location.reload());
}

/**
 * Trix attachments are only wired up for vignette questionnaires, so a file
 * dropped into the home intro would never be uploaded. The toolbar button is
 * hidden via CSS (lectures.scss); this closes the drag & drop and paste paths
 * too. Scoped to this one editor so that vignettes keep working.
 */
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
