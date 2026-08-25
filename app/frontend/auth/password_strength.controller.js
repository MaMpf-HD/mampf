import { Controller } from "@hotwired/stimulus";

// The server scores with the Ruby port of zxcvbn, which is a generation older
// than the one in the browser and rates concatenated words far lower. Only a 4
// here reliably means the server will take it, so anything below stays amber.
const ACCEPTED_SCORE = 4;

// The dictionaries weigh more than the whole application bundle, and only the
// three Devise password forms need them, so they are fetched when one appears.
let loading;

function currentLanguage() {
  const locale = document.body?.dataset.locale || document.documentElement.lang || "en";
  return locale.toLowerCase().startsWith("de") ? "de" : "en";
}

async function loadZxcvbn() {
  const language = currentLanguage();
  const [core, common, languagePackage] = await Promise.all([
    import("@zxcvbn-ts/core"),
    import("@zxcvbn-ts/language-common"),
    language === "de"
      ? import("@zxcvbn-ts/language-de")
      : import("@zxcvbn-ts/language-en"),
  ]);

  core.zxcvbnOptions.setOptions({
    translations: languagePackage.translations,
    graphs: common.adjacencyGraphs,
    dictionary: {
      ...common.dictionary,
      ...languagePackage.dictionary,
    },
  });

  return core.zxcvbn;
}

function zxcvbnReady() {
  loading ||= loadZxcvbn();
  return loading;
}

export default class extends Controller {
  static targets = ["password", "passwordConfirmation", "email", "name", "meter", "feedback"];
  static values = {
    weakText: String,
    fairText: String,
    almostText: String,
    strongText: String,
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

    this.updateMeter(score);
    this.updateFeedback(score, warning);
  }

  clearFieldError(fieldOrEvent) {
    const field = fieldOrEvent?.target || fieldOrEvent;
    if (!field) return;

    field.classList.remove("is-invalid");
    const nextElement = field.nextElementSibling;
    if (nextElement?.classList.contains("invalid-feedback")) {
      nextElement.remove();
    }
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
