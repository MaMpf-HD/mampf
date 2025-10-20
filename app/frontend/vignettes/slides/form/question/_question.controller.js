import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["questionType", "text", "textLabel", "multipleChoice", "number", "likert"];

  connect() {
    this.showOnlyQuestionType(this.questionTypeTarget.value);
  }

  changeQuestionType(event) {
    this.showOnlyQuestionType(event.target.value);
    const customEvent = new CustomEvent("vignettes:questionTypeChanged",
      { detail: { value: event.target.value }, bubbles: true });
    this.element.dispatchEvent(customEvent);
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
      $(this.textLabelTarget).collapse("show");
    }

    const multipleChoiceInput = this.multipleChoiceTarget.querySelector("input");
    if (questionType === "Vignettes::MultipleChoiceQuestion") {
      if (multipleChoiceInput) {
        multipleChoiceInput.required = true;
        multipleChoiceInput.disabled = false;
      }
      $(this.multipleChoiceTarget).collapse("show");
    }
    else {
      if (multipleChoiceInput) {
        multipleChoiceInput.required = false;
        multipleChoiceInput.disabled = true;
      }
      $(this.multipleChoiceTarget).collapse("hide");
    }

    if (questionType === "Vignettes::NumberQuestion") {
      this.numberTarget.querySelector("input").disabled = false;
      $(this.numberTarget).collapse("show");
    }
    else {
      this.numberTarget.querySelector("input").disabled = true;
      $(this.numberTarget).collapse("hide");
    }

    if (questionType === "Vignettes::LikertScaleQuestion") {
      this.likertTarget.querySelector("select").disabled = false;
      $(this.likertTarget).collapse("show");
    }
    else {
      this.likertTarget.querySelector("select").disabled = true;
      $(this.likertTarget).collapse("hide");
    }
  }
}
