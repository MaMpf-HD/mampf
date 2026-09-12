/**
 * Only the editors that Action Text wired carry a `data-direct-upload-url`, and
 * only those can store a file. Everywhere else the trix-rails helper renders a
 * bare editor, where the attachment button used to accept a file, post it to
 * nowhere and drop it again.
 */
function attachmentsAreWired(editor) {
  return Boolean(editor?.dataset?.directUploadUrl);
}

document.addEventListener("trix-file-accept", (event) => {
  if (!attachmentsAreWired(event.target)) {
    event.preventDefault();
  }
});

document.addEventListener("trix-initialize", (event) => {
  if (attachmentsAreWired(event.target)) {
    return;
  }

  event.target.toolbarElement
    ?.querySelector("[data-trix-button-group='file-tools']")
    ?.remove();
});
