import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "button"];
  static classes = ["hidden"];

  show() {
    this.formTarget.classList.remove(this.hiddenClass);
    this.buttonTarget.classList.add(this.hiddenClass);
    this.formTarget.querySelector("input:not([type='hidden'])")?.focus();
  }

  cancel() {
    this.formTarget.classList.add(this.hiddenClass);
    this.buttonTarget.classList.remove(this.hiddenClass);
    this.formTarget.querySelector("form")?.reset();
    this.clearErrors();
  }

  clearErrors() {
    this.formTarget.querySelectorAll(".is-invalid").forEach(el => el.classList.remove("is-invalid"));
    this.formTarget.querySelectorAll(".invalid-feedback").forEach((el) => {
      el.textContent = "";
    });
  }
}
