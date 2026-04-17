import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.update(false);
  }

  handleMarkState(event) {
    const [typeAction, campaignId] = event.submitter.name.split("_");
    if (typeAction === "reset" || typeAction === "save") {
      this.reset(campaignId);
    }
    else if (typeAction === "up" || typeAction === "down"
      || typeAction === "remove" || typeAction === "add") {
      this.mark(campaignId);
    }
  }

  mark(campaignId) {
    this.update(true, campaignId);
  }

  reset(campaignId) {
    this.update(false, campaignId);
  }

  update(status, campaignId) {
    try {
      const ele = document.querySelector(`.required-touch-display-${campaignId}`);
      if (!ele) return;

      if (status === true)
        ele.classList.remove("d-none");
      else
        ele.classList.add("d-none");
    }
    catch { /* Element might not exist, ignore */ }
  }
}
