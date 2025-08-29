$(document).on("turbo:load", () => {
  const vignetteTitleInput = $("#new-vignette-title");

  $("#vignetteModal").on("shown.bs.modal", () => {
    vignetteTitleInput.focus();
  });
});
