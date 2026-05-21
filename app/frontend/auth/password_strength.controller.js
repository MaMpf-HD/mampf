import { Controller } from "@hotwired/stimulus";
import { zxcvbn, zxcvbnOptions } from "@zxcvbn-ts/core";
import * as zxcvbnCommonPackage from "@zxcvbn-ts/language-common";
import * as zxcvbnEnPackage from "@zxcvbn-ts/language-en";
import * as zxcvbnDePackage from "@zxcvbn-ts/language-de";

let configuredLanguage;

function setupZxcvbnOptions() {
  const locale = document.body?.dataset.locale || document.documentElement.lang || "en";
  const language = locale.toLowerCase().startsWith("de") ? "de" : "en";

  if (configuredLanguage === language) return;

  const languagePackage = language === "de" ? zxcvbnDePackage : zxcvbnEnPackage;

  zxcvbnOptions.setOptions({
    translations: languagePackage.translations,
    graphs: languagePackage.adjacencyGraphs,
    dictionary: {
      ...zxcvbnCommonPackage.dictionary,
      ...languagePackage.dictionary,
    },
  });

  configuredLanguage = language;
}

export default class extends Controller {
  static targets = ["password", "email", "name", "meter", "feedback"];
  static values = {
    weakText: { type: String, default: "Weak" },
    fairText: { type: String, default: "Fair" },
    goodText: { type: String, default: "Good" },
    strongText: { type: String, default: "Strong" },
    localIdentifiers: Array,
    minLength: { type: Number, default: 15 },
    tooShortText: { type: String, default: "Must be at least 15 characters" },
  };

  connect() {
    setupZxcvbnOptions();
    this.check();
  }

  check() {
    const password = this.hasPasswordTarget ? this.passwordTarget.value : "";

    if (!password) {
      if (this.hasMeterTarget) {
        this.meterTarget.style.width = "0%";
        this.meterTarget.className = "progress-bar";
      }
      if (this.hasFeedbackTarget) {
        this.feedbackTarget.textContent = "";
      }
      return;
    }

    const userInputs = [];
    if (this.hasEmailTarget && this.emailTarget.value) {
      userInputs.push(this.emailTarget.value);
    }
    if (this.hasNameTarget && this.nameTarget.value) {
      userInputs.push(this.nameTarget.value);
    }
    if (this.hasLocalIdentifiersValue) {
      userInputs.push(...this.localIdentifiersValue);
    }

    const result = zxcvbn(password, userInputs);
    let score = result.score;
    let warning = result.feedback ? result.feedback.warning : "";

    if (password.length < this.minLengthValue) {
      score = Math.min(score, 2);
      warning = this.tooShortTextValue;
    }

    this.updateMeter(score);
    this.updateFeedback(score, warning);
  }

  updateMeter(score) {
    if (!this.hasMeterTarget) return;

    const percentages = ["20%", "40%", "60%", "80%", "100%"];
    const classes = [
      "progress-bar bg-danger",
      "progress-bar bg-danger",
      "progress-bar bg-warning",
      "progress-bar bg-success",
      "progress-bar bg-success",
    ];

    this.meterTarget.style.width = percentages[score];
    this.meterTarget.className = classes[score];
  }

  updateFeedback(score, warning) {
    if (!this.hasFeedbackTarget) return;

    let text = "";
    switch (score) {
      case 0:
      case 1:
        text = this.weakTextValue;
        break;
      case 2:
        text = this.fairTextValue;
        break;
      case 3:
        text = this.goodTextValue;
        break;
      case 4:
        text = this.strongTextValue;
        break;
    }

    if (score < 3 && warning) {
      text += ` - ${warning}`;
    }

    this.feedbackTarget.textContent = text;

    if (score < 3) {
      this.feedbackTarget.className = "form-text text-danger mt-1";
    }
    else {
      this.feedbackTarget.className = "form-text text-success mt-1";
    }
  }
}
