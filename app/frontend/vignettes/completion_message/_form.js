function handleComplectionMessagesChanges() {
  const completionSaveButton = $("#completion-message-save-button");
  const changesWarningDiv = $("#unsaved-changes-warning");
  const trixEditor = document.querySelector("trix-editor");

  if (!trixEditor || !completionSaveButton) return;

  $(document).on("trix-change", "trix-editor", function () {
    completionSaveButton.removeClass("d-none");
    changesWarningDiv.removeClass("d-none");
  });
}

$(document).on("turbo:load", function () {
  handleComplectionMessagesChanges();
});
