import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["submitButton", "warning", "maxTeamSize", "gracePeriod"];

  connect() {
    this.originalMaxTeamSize = this.maxTeamSizeTarget.value;
    this.originalGracePeriod = this.gracePeriodTarget.value;
    this.hideSubmitElements();
  }

  checkForChanges() {
    const maxTeamSizeChanged = this.maxTeamSizeTarget.value !== this.originalMaxTeamSize;
    const gracePeriodChanged = this.gracePeriodTarget.value !== this.originalGracePeriod;

    if (maxTeamSizeChanged || gracePeriodChanged) {
      this.showSubmitElements();
    }
    else {
      this.hideSubmitElements();
    }
  }

  showSubmitElements() {
    this.submitButtonTarget.classList.remove("d-none");
    this.warningTarget.classList.remove("d-none");
  }

  hideSubmitElements() {
    this.submitButtonTarget.classList.add("d-none");
    this.warningTarget.classList.add("d-none");
  }

  cancel() {
    this.maxTeamSizeTarget.value = this.originalMaxTeamSize;
    this.gracePeriodTarget.value = this.originalGracePeriod;
    this.hideSubmitElements();
  }

  resetAfterSave() {
    this.originalMaxTeamSize = this.maxTeamSizeTarget.value;
    this.originalGracePeriod = this.gracePeriodTarget.value;
    this.hideSubmitElements();
  }
}
