var QUESTION_TYPE_SELECT_ID = "#vignettes-question-type-select";

$(document).ready(function () {
  handleQuestionTypes();
  updateQuestionFieldState($(QUESTION_TYPE_SELECT_ID).val());
  new TomSelect(QUESTION_TYPE_SELECT_ID, { allowEmptyOption: true });
  handleMultipleChoiceEditor();
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
