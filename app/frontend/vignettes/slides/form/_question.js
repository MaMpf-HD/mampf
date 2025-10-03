const QUESTION_TYPE_SELECT_ID = "vignettes-question-type-select";

function initializeQuestionForm(slideForm) {
  const slideId = slideForm.getAttribute("data-slide-id");
  if (!slideId) return;

  const questionTypeSelect = slideForm.querySelector(`#${QUESTION_TYPE_SELECT_ID}-${slideId}`);
  if (!questionTypeSelect) return;

  if (!questionTypeSelect.tomselect) {
    new TomSelect(questionTypeSelect, { allowEmptyOption: true });
  }

  updateQuestionFieldState(slideForm, slideId, questionTypeSelect.value);
  questionTypeSelect.addEventListener("change", function (event) {
    updateQuestionFieldState(slideForm, slideId, event.target.value);
  });

  handleMultipleChoiceEditor(slideForm, slideId);
  handleNumberOptions(slideForm, slideId);
}

function updateQuestionFieldState(slideForm, slideId, selectedValue) {
  console.log("update question field state");
  const scopedId = name => `#${name}-${slideId}`;

  const multipleChoiceField = slideForm.querySelector(scopedId("vignette-edit-multiple-choice"));
  const questionTextField = slideForm.querySelector(scopedId("vignette-question-text"));
  const questionLabel = questionTextField.querySelector("label");
  const numberQuestionOptionContainer = slideForm.querySelector(scopedId("vignette-number-question-options"));
  const likertScaleLanguageSelection = slideForm.querySelector(scopedId("vignette-likert-scale-language-selection"));
  const textArea = questionTextField.querySelector("textarea");

  // Type: "No answer"
  if (selectedValue === "") {
    questionLabel.textContent = "Your Question or leave empty";
    textArea.removeAttribute("required");
  }
  else {
    questionLabel.textContent = "Your Question";
    textArea.setAttribute("required", true);
    $(questionTextField).collapse("show");
  }

  if (selectedValue === "Vignettes::MultipleChoiceQuestion") {
    $(multipleChoiceField).collapse("show");
    multipleChoiceField.querySelectorAll("input").forEach((input) => {
      input.removeAttribute("disabled");
      input.setAttribute("required", true);
    });
  }
  else {
    $(multipleChoiceField).collapse("hide");
    multipleChoiceField.querySelectorAll("input").forEach((input) => {
      input.setAttribute("disabled", "disabled");
      input.removeAttribute("required");
    });
  }

  if (selectedValue === "Vignettes::NumberQuestion") {
    $(numberQuestionOptionContainer).collapse("show");
    numberQuestionOptionContainer.querySelectorAll("input")
      .forEach(input => input.removeAttribute("disabled"));
  }
  else {
    $(numberQuestionOptionContainer).collapse("hide");
    numberQuestionOptionContainer.querySelectorAll("input")
      .forEach(input => input.setAttribute("disabled", "disabled"));
  }

  if (selectedValue === "Vignettes::LikertScaleQuestion") {
    $(likertScaleLanguageSelection).collapse("show");
    likertScaleLanguageSelection.querySelectorAll("input")
      .forEach(input => input.removeAttribute("disabled"));
  }
  else {
    $(likertScaleLanguageSelection).collapse("hide");
    likertScaleLanguageSelection.querySelectorAll("input")
      .forEach(input => input.setAttribute("disabled", "disabled"));
  }
}

function handleMultipleChoiceEditor(slideForm, slideId) {
  const scopedId = name => `#${name}-${slideId}`;
  const addButton = slideForm.querySelector(scopedId("vignette-multiple-choice-add"));
  const optionsContainer = slideForm.querySelector(scopedId("vignette-multiple-choice-options"));
  const template = slideForm.querySelector(scopedId("vignette-multiple-choice-options-template"));

  if (!addButton) return;

  addButton.addEventListener("click", function (_evt) {
    const newOptionHtml = template.innerHTML;
    const uniqueId = `${slideId}-${new Date().getTime()}`;
    const newBlockHtml = newOptionHtml.replace(/NEW_RECORD/g, uniqueId);
    optionsContainer.insertAdjacentHTML("beforeend", newBlockHtml);
  });

  slideForm.addEventListener("click", function (evt) {
    if (!evt.target.closest(".remove-vignette-mc-option")) {
      return;
    }

    const parentDiv = $(evt.target).closest("div");
    parentDiv.find("input").removeAttr("required");
    parentDiv.find(".vignette-mc-hidden-destroy").val("1");
    parentDiv.removeClass("d-flex").hide();
  });
}

function handleNumberOptions(slideForm, slideId) {
  const scopedId = name => `#${name}-${slideId}`;
  const minField = slideForm.querySelector(scopedId("vignette-number-min"));
  const maxField = slideForm.querySelector(scopedId("vignette-number-max"));

  if (!minField || !maxField) {
    return;
  }

  function validateMinMax() {
    if (minField.value && maxField.value) {
      const minValue = parseFloat(minField.value);
      const maxValue = parseFloat(maxField.value);

      if (minValue >= maxValue) {
        minField.setCustomValidity("Minimum value must be less than maximum");
        maxField.setCustomValidity("Maximum value must be greater than minimum");
      }
      else {
        minField.setCustomValidity("");
        maxField.setCustomValidity("");
      }
    }
    else {
      minField.setCustomValidity("");
      maxField.setCustomValidity("");
    }
  }

  minField.addEventListener("input", validateMinMax);
  maxField.addEventListener("input", validateMinMax);
}

document.addEventListener("turbo:frame-render", function () {
  const slideForms = document.querySelectorAll(".slide-form");
  slideForms.forEach((slideForm) => {
    initializeQuestionForm(slideForm);
  });
});
