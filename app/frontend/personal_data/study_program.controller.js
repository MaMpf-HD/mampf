import { Controller } from "@hotwired/stimulus";

/**
 * Leads from the degree to the program: a student of two subjects who has
 * mathematics among them gets its program without picking, everybody else
 * picks among the programs of the degree.
 */
export default class extends Controller {
  static targets = ["degree", "mathQuestion", "math", "choice", "option", "other"];

  connect() {
    this.update();
  }

  update() {
    const degree = this.degreeTargets.find(radio => radio.checked);
    const mathProgram = degree?.dataset.twoSubjects === "true" && degree.dataset.mathProgram;
    const studiesMath = this.mathTargets.find(radio => radio.checked)?.value;
    const listed = degree !== undefined && degree.value !== "other"
      && (!mathProgram || studiesMath === "no");

    this.mathQuestionTarget.hidden = !mathProgram;
    for (const radio of this.mathTargets) radio.required = Boolean(mathProgram);
    this.choiceTarget.hidden = !listed;
    for (const option of this.optionTargets) {
      const radio = option.querySelector("input");
      const shown = listed && [degree.value, "any"].includes(option.dataset.degree)
        && !(mathProgram && option.dataset.math === "true");
      option.hidden = !shown;
      radio.required = shown;
      if (!shown) radio.checked = false;
    }

    this.otherTarget.checked = degree?.value === "other";
    if (mathProgram && studiesMath === "yes") {
      this.element.querySelector(`input[value="${mathProgram}"][name="user[program_id]"]`)
        .checked = true;
    }
  }
}
