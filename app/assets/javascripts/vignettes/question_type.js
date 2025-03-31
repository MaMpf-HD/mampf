var QUESTION_TYPE_SELECT_ID = "#vignettes-question-type-select";

$(document).ready(function () {
  handleQuestionTypes();
  updateQuestionFieldState($(QUESTION_TYPE_SELECT_ID).val());
  new TomSelect(QUESTION_TYPE_SELECT_ID, { allowEmptyOption: true });
  handleMultipleChoiceEditor();
  handleNumberOptions();
});

function handleQuestionTypes() {
  const questionTypeDropdown = $(QUESTION_TYPE_SELECT_ID);

  questionTypeDropdown.on("change", function (event) {
    updateQuestionFieldState(event.target.value);
  });
}

function updateQuestionFieldState(selectedName) {
  const multipleChoiceField = $("#vignette-edit-multiple-choice");
  const questionTextField = $("#vignette-question-text");
  const numberQuestionOptionContainer = $("#vignette-number-question-options");
  const likertScaleLanguageSelection = $("#vignette-likert-scale-language-selection");
  const textArea = questionTextField.find("textarea");

  // Type "No question"
  if (selectedName === "") {
    questionTextField.find("textarea").val("");
    questionTextField.collapse("hide");
    textArea.removeAttr("required");
  }
  else {
    textArea.attr("required", true);
    questionTextField.collapse("show");
  }

  if (selectedName === "Vignettes::MultipleChoiceQuestion") {
    multipleChoiceField.collapse("show");
    multipleChoiceField.find("input").removeAttr("disabled");
    multipleChoiceField.find("input").attr("required", true);
  }
  else {
    multipleChoiceField.collapse("hide");
    multipleChoiceField.find("input").attr("disabled", "disabled");
    multipleChoiceField.find("input").removeAttr("required");
  }

  if (selectedName === "Vignettes::NumberQuestion") {
    numberQuestionOptionContainer.collapse("show");
    numberQuestionOptionContainer.find("input").removeAttr("disabled");
  }
  else {
    numberQuestionOptionContainer.collapse("hide");
    numberQuestionOptionContainer.find("input").attr("disabled", "disabled");
  }

  if (selectedName === "Vignettes::LikertScaleQuestion") {
    likertScaleLanguageSelection.collapse("show");
    likertScaleLanguageSelection.find("input").removeAttr("disabled");
  }
  else {
    likertScaleLanguageSelection.collapse("hide");
    likertScaleLanguageSelection.find("input").attr("disabled", "disabled");
  }
}

function handleMultipleChoiceEditor() {
  // Adding an option
  $("#vignette-multiple-choice-add").click(function (_evt) {
    const template = $("#vignette-multiple-choice-options-template");
    const newOptionHtml = template.html();
    const uniqueId = new Date().getTime();
    const newBlockHtml = newOptionHtml.replace(/NEW_RECORD/g, uniqueId);
    $("#vignette-multiple-choice-options").append(newBlockHtml);
  });

  // Removing an option
  $(document).on("click", ".remove-vignette-mc-option", function (evt) {
    const parentDiv = $(evt.target).closest("div");
    parentDiv.find("input").removeAttr("required");
    parentDiv.find(".vignette-mc-hidden-destroy").val("1");
    parentDiv.removeClass("d-flex").hide();
  });
}

function handleNumberOptions() {
  const minField = $("#vignette-number-min");
  const maxField = $("#vignette-number-max");

  if (!minField.length || !maxField.length) {
    return;
  }

  function validateMinMax() {
    if (minField.val() && maxField.val()) {
      const minValue = parseFloat(minField.val());
      const maxValue = parseFloat(maxField.val());

      if (minValue >= maxValue) {
        minField[0].setCustomValidity("Minimum value must be less than maximum");
        maxField[0].setCustomValidity("Maximum value must be greater than minimum");
      }
      else {
        minField[0].setCustomValidity("");
        maxField[0].setCustomValidity("");
      }
    }
    else {
      minField[0].setCustomValidity("");
      maxField[0].setCustomValidity("");
    }
  }

  minField.on("input", validateMinMax);
  maxField.on("input", validateMinMax);
}
