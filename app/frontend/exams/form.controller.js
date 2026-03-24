import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["warning", "submitButton", "cancelButton", "title", "date",
    "location", "capacity", "description", "skipCampaigns", "deadlineGroup"];

  connect() {
    this.storeOriginalValues();
    this.hideSubmitElements();
  }

  storeOriginalValues() {
    this.originalTitle = this.titleTarget.value;
    this.originalDate = this.dateTarget.value;
    this.originalLocation = this.locationTarget.value;
    this.originalCapacity = this.capacityTarget.value;
    this.originalDescription = this.descriptionTarget.value;
    this.originalSkipCampaigns = this.hasSkipCampaignsTarget
      ? this.skipCampaignsTarget.checked
      : false;
  }

  checkForChanges() {
    const titleChanged = this.titleTarget.value !== this.originalTitle;
    const dateChanged = this.dateTarget.value !== this.originalDate;
    const locationChanged = this.locationTarget.value !== this.originalLocation;
    const capacityChanged = this.capacityTarget.value !== this.originalCapacity;
    const descriptionChanged = this.descriptionTarget.value !== this.originalDescription;
    const skipCampaignsChanged = this.hasSkipCampaignsTarget
      && this.skipCampaignsTarget.checked !== this.originalSkipCampaigns;

    if (titleChanged || dateChanged || locationChanged || capacityChanged
      || descriptionChanged || skipCampaignsChanged) {
      this.showSubmitElements();
    }
    else {
      this.hideSubmitElements();
    }
  }

  showSubmitElements() {
    this.submitButtonTarget.classList.remove("d-none");
    this.cancelButtonTarget.classList.remove("d-none");
    this.warningTarget.classList.remove("d-none");
  }

  hideSubmitElements() {
    this.submitButtonTarget.classList.add("d-none");
    this.cancelButtonTarget.classList.add("d-none");
    this.warningTarget.classList.add("d-none");
  }

  cancel() {
    this.titleTarget.value = this.originalTitle;
    this.dateTarget.value = this.originalDate;
    this.locationTarget.value = this.originalLocation;
    this.capacityTarget.value = this.originalCapacity;
    this.descriptionTarget.value = this.originalDescription;
    if (this.hasSkipCampaignsTarget) {
      this.skipCampaignsTarget.checked = this.originalSkipCampaigns;
    }
    this.hideSubmitElements();
  }

  resetAfterSave() {
    this.storeOriginalValues();
    this.hideSubmitElements();
  }

  toggleDeadline() {
    if (!this.hasDeadlineGroupTarget) return;

    const hidden = this.hasSkipCampaignsTarget
      && this.skipCampaignsTarget.checked;
    this.deadlineGroupTarget.style.display = hidden ? "none" : "";
  }
}
