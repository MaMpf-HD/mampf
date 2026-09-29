import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["changeButton", "requestDataToast"];

  showChangeBanner() {
    for (const button of this.changeButtonTargets) {
      button.classList.remove("d-none");
    }
  }

  showRequestDataToast() {
    const toast = this.requestDataToastTarget;
    bootstrap.Toast.getOrCreateInstance(toast).show();
  }
}
