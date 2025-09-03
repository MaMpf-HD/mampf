$(document).on("turbo:load", function () {
  const codenameInput = document.getElementById("codename-input");
  if (!codenameInput) {
    return;
  }

  const minLength = parseInt(codenameInput.dataset.minLength, 10) || 3;
  const maxLength = parseInt(codenameInput.dataset.maxLength, 10) || 16;
  const emptyMessage = codenameInput.dataset.emptyMessage;
  const minMessage = codenameInput.dataset.minMessage;
  const maxMessage = codenameInput.dataset.maxMessage;

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

  const saveButton = document.getElementById("codename-save-button");
  saveButton.addEventListener("click", function () {
    codenameInput.reportValidity();
  });
});
