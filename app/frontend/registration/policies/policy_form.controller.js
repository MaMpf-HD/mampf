import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["kindSelect", "configSection"];

  connect() {
    this.changeKind();
  }

  changeKind() {
    const selectedKind = this.kindSelectTarget.value;
    this.configSectionTargets.forEach((section) => {
      if (section.dataset.kind === selectedKind) {
        section.classList.remove("d-none");
        // Enable inputs inside
        section.querySelectorAll("input, select").forEach(input => input.disabled = false);
      }
      else {
        section.classList.add("d-none");
        // Disable inputs inside to prevent submission
        section.querySelectorAll("input, select").forEach(input => input.disabled = true);
      }
    });
  }
}
