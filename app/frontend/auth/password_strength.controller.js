import { Controller } from "@hotwired/stimulus";

// Browser and server score with different zxcvbn generations. Below 4 the
// browser regularly praises a password the server then refuses.
const ACCEPTED_SCORE = 4;

// Fetched on demand: the dictionaries dwarf the rest of the page and only the
// password forms need them. Kept per language, because switching language is a
// Turbo visit and leaves this module in place.
const packs = new Map();
let configuredLanguage;

function currentLanguage() {
  const locale = document.body?.dataset.locale || document.documentElement.lang || "en";
  return locale.toLowerCase().startsWith("de") ? "de" : "en";
}

function loadPack(language) {
  return Promise.all([
    import("@zxcvbn-ts/core"),
    import("@zxcvbn-ts/language-common"),
    language === "de"
      ? import("@zxcvbn-ts/language-de")
      : import("@zxcvbn-ts/language-en"),
  ]);
}

async function zxcvbnReady() {
  const language = currentLanguage();
  if (!packs.has(language)) packs.set(language, loadPack(language));

  const [core, common, languagePackage] = await packs.get(language);
  if (configuredLanguage !== language) {
    core.zxcvbnOptions.setOptions({
      translations: languagePackage.translations,
      graphs: common.adjacencyGraphs,
      dictionary: {
        ...common.dictionary,
        ...languagePackage.dictionary,
      },
    });
    configuredLanguage = language;
  }

  return core.zxcvbn;
}

export default class extends Controller {
  static targets = ["password", "passwordConfirmation", "email", "name", "meter",
    "meterContainer", "feedback"];

  static values = {
    weakText: String,
    fairText: String,
    almostText: String,
    strongText: String,
    mismatchText: String,
    localIdentifiers: Array,
    minLength: Number,
    tooShortText: String,
  };

  connect() {
    zxcvbnReady();
  }

  async check() {
    if (this.hasPasswordTarget) {
      this.clearFieldError(this.passwordTarget);
    }
    if (this.hasPasswordConfirmationTarget) {
      this.clearFieldError(this.passwordConfirmationTarget);
    }

    const password = this.hasPasswordTarget ? this.passwordTarget.value : "";

    if (!password) {
      if (this.hasMeterTarget) {
        this.meterTarget.style.width = "0%";
        this.meterTarget.className = "progress-bar";
      }
      if (this.hasFeedbackTarget) {
        this.feedbackTarget.textContent = "";
      }
      this.showMeter(false);
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

    const zxcvbn = await zxcvbnReady();
    if (this.passwordTarget.value !== password) return;

    const result = zxcvbn(password, userInputs);
    let score = result.score;
    let warning = result.feedback ? result.feedback.warning : "";

    if (this.minLengthValue && password.length < this.minLengthValue) {
      score = Math.min(score, 2);
      warning = this.tooShortTextValue;
    }

    this.showMeter(true);
    this.updateMeter(score);
    this.updateFeedback(score, warning);
  }

  // Devise checks this too; catching it here saves a submit.
  checkMatch() {
    if (!this.hasPasswordTarget || !this.hasPasswordConfirmationTarget) return;

    const confirmation = this.passwordConfirmationTarget.value;
    if (!confirmation || confirmation === this.passwordTarget.value) {
      this.clearFieldError(this.passwordConfirmationTarget);
      return;
    }

    this.markFieldInvalid(this.passwordConfirmationTarget, this.mismatchTextValue);
  }

  clearFieldError(fieldOrEvent) {
    const field = fieldOrEvent?.target || fieldOrEvent;
    if (!field) return;

    field.classList.remove("is-invalid");
    for (const message of field.parentElement?.querySelectorAll(".invalid-feedback") || []) {
      message.remove();
    }
  }

  markFieldInvalid(field, message) {
    if (!message) return;

    this.clearFieldError(field);
    field.classList.add("is-invalid");

    const error = document.createElement("span");
    error.className = "invalid-feedback d-block";
    error.setAttribute("aria-live", "polite");
    error.textContent = message;
    field.parentElement.append(error);
  }

  showMeter(visible) {
    if (!this.hasMeterContainerTarget) return;

    this.meterContainerTarget.classList.toggle("d-none", !visible);
  }

  updateMeter(score) {
    if (!this.hasMeterTarget) return;

    const percentages = ["20%", "40%", "60%", "80%", "100%"];
    const classes = [
      "progress-bar bg-danger",
      "progress-bar bg-danger",
      "progress-bar bg-warning",
      "progress-bar bg-warning",
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
        text = this.almostTextValue;
        break;
      case 4:
        text = this.strongTextValue;
        break;
    }

    if (score < ACCEPTED_SCORE && warning) {
      text += ` - ${warning}`;
    }

    this.feedbackTarget.textContent = text;

    if (score < ACCEPTED_SCORE) {
      this.feedbackTarget.className = "form-text text-danger mt-1";
    }
    else {
      this.feedbackTarget.className = "form-text text-success mt-1";
    }
  }
}
