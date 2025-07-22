$(document).ready(function () {
  const codenameInput = document.getElementById("codename-input");
  const saveButton = document.getElementById("codename-save-button");
  // TODO: find a way to sync this with backend without having to use ERB syntax
  const minLength = 3;
  const maxLength = 16;

  const emptyMessage = codenameInput.dataset.emptyMessage;
  const minMessage = codenameInput.dataset.minMessage;
  const maxMessage = codenameInput.dataset.maxMessage;

  if (codenameInput) {
    codenameInput.setCustomValidity(emptyMessage);

    codenameInput.addEventListener("input", function () {
      if (this.validity.valueMissing) {
        this.setCustomValidity(emptyMessage);
      }
      else if (this.value.length < minLength) {
        this.setCustomValidity(minMessage);
      }
      else if (this.value.length > maxLength) {
        this.setCustomValidity(maxMessage);
      }
      else {
        this.setCustomValidity("");
      }
    });

    saveButton.addEventListener("click", function () {
      codenameInput.reportValidity();
    });
  }
});
