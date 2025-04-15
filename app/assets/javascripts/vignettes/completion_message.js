$(document).ready(function () {
  const buttonDiv = $("#completion-message-buttons");
  const changesWarningDiv = $("#unsaved-changes-warning");
  const trixEditor = document.querySelector("trix-editor");

  if (!trixEditor || !buttonDiv) return;

  $(document).on("trix-change", "trix-editor", function () {
    buttonDiv.removeClass("d-none");
    changesWarningDiv.removeClass("d-none");
  });
});
