$(document).on("turbo:load", function () {
  const codenameInput = document.getElementById("codename-input");
  const saveButton = document.getElementById("codename-save-button");

  const emptyMessage = codenameInput.dataset.emptyMessage;
  const minMessage = codenameInput.dataset.minMessage;
  const maxMessage = codenameInput.dataset.maxMessage;

  if (codenameInput) {
    codenameInput.setCustomValidity(emptyMessage);

    const minLength = parseInt(codenameInput.dataset.minLength, 10) || 3;
    const maxLength = parseInt(codenameInput.dataset.maxLength, 10) || 16;

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
