import { Controller } from "@hotwired/stimulus";
import { Collapse } from "bootstrap";

export default class extends Controller {
  static targets = ["questionType", "text", "textLabel", "multipleChoice", "number", "likert"];

  connect() {
    this.textCollapse = new Collapse(this.textTarget, { toggle: false });
    this.multipleChoiceCollapse = new Collapse(this.multipleChoiceTarget, { toggle: false });
    this.numberCollapse = new Collapse(this.numberTarget, { toggle: false });
    this.likertCollapse = new Collapse(this.likertTarget, { toggle: false });

    this.showOnlyQuestionType(this.questionTypeTarget.value);
  }

  changeQuestionType(event) {
    this.showOnlyQuestionType(event.target.value);
  }

  showOnlyQuestionType(questionType) {
    // Type "No answer"
    const textArea = this.textTarget.querySelector("textarea");
    if (questionType === "") {
      this.textLabelTarget.textContent = "Your Question or leave empty";
      textArea.required = false;
    }
    else {
      this.textLabelTarget.textContent = "Your Question";
      textArea.required = true;
      this.textCollapse.show();
    }

    const multipleChoiceInput = this.multipleChoiceTarget.querySelector("input");
    if (questionType === "Vignettes::MultipleChoiceQuestion") {
      if (multipleChoiceInput) {
        multipleChoiceInput.required = true;
        multipleChoiceInput.disabled = false;
      }
      this.multipleChoiceCollapse.show();
    }
    else {
      if (multipleChoiceInput) {
        multipleChoiceInput.required = false;
        multipleChoiceInput.disabled = true;
      }
      this.multipleChoiceCollapse.hide();
    }

    if (questionType === "Vignettes::NumberQuestion") {
      this.numberTarget.querySelector("input").disabled = false;
      this.numberCollapse.show();
    }
    else {
      this.numberTarget.querySelector("input").disabled = true;
      this.numberCollapse.hide();
    }

    if (questionType === "Vignettes::LikertScaleQuestion") {
      this.likertTarget.querySelector("select").disabled = false;
      this.likertCollapse.show();
    }
    else {
      this.likertTarget.querySelector("select").disabled = true;
      this.likertCollapse.hide();
    }
  }
}
