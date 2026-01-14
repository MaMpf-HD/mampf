import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "helpText"];
  static values = {
    tutorialHelp: String,
    talkHelp: String,
    enrollmentHelp: String,
    planningHelp: String,
    otherHelp: String,
  };

  connect() {
    this.updateHelp();
  }

  updateHelp() {
    const type = this.selectTarget.value;
    const helpTexts = {
      "Tutorial": this.tutorialHelpValue,
      "Talk": this.talkHelpValue,
      "Enrollment Group": this.enrollmentHelpValue,
      "Planning Survey": this.planningHelpValue,
      "Other Group": this.otherHelpValue,
    };

    this.helpTextTarget.textContent = helpTexts[type] || "";
    this.helpTextTarget.style.display = type ? "block" : "none";
  }
}
