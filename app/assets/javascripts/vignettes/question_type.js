var QUESTION_TYPE_SELECT_ID = "#vignettes-question-type-select";

$(document).ready(function () {
  handleQuestionTypes();
  updateQuestionFieldState($(QUESTION_TYPE_SELECT_ID).val());
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

  // Type "No question"
  if (selectedName === "") {
    questionTextField.find("textarea").val("");
    questionTextField.collapse("hide");
  }
  else {
    questionTextField.collapse("show");
  }

  if (selectedName === "Vignettes::MultipleChoiceQuestion") {
    multipleChoiceField.collapse("show");
  }
  else {
    multipleChoiceField.collapse("hide");
  }
}

function handleMultipleChoiceEditor() {
  $("#vignette-multiple-choice-add").click(function (_evt) {
    const template = $("#vignette-multiple-choice-options-template");
    const newOptionHtml = template.html();
    const uniqueId = new Date().getTime();
    const newBlockHtml = newOptionHtml.replace(/NEW_RECORD/g, uniqueId);
    $("#vignette-multiple-choice-options").append(newBlockHtml);
  });
}
