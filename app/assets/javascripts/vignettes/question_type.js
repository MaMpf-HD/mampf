var QUESTION_TYPE_SELECT_ID = "#vignettes-question-type-select";

function handleQuestionTypes() {
  const questionTypeDropdown = $(QUESTION_TYPE_SELECT_ID);

  questionTypeDropdown.on("change", function (event) {
    updateQuestionFieldState(event.target.value);
  });
}

function updateQuestionFieldState(selectedName) {
  const questionFields = $(".vignette-question-field");
  questionFields.each(function () {
    $(this).collapse("hide");
  });

  const questionField = $("#vignette-question-text");

  // Type "No question" selected
  if (selectedName === "") {
    questionField.find("textarea").val("");
    questionField.collapse("hide");
  }
  else {
    questionField.collapse("show");
    if (selectedName === "Vignettes::MultipleChoiceQuestion") {
      $("#vignette-edit-multiple-choice").collapse("show");
    }
  }
}

$(document).ready(function () {
  handleQuestionTypes();
  updateQuestionFieldState($(QUESTION_TYPE_SELECT_ID).val());
});

// document.addEventListener("turbolinks:load", () => {
//   const optionsContainer = document.getElementById("options-container");

//   // Handle dynamic addition of options
//   const addOptionButton = document.getElementById("add-option");
//   const optionTemplate = document.getElementById("new-option-template");
//   if (addOptionButton) {
//     addOptionButton.addEventListener("click", () => {
//       const optionTemplateHTML = optionTemplate.innerHTML;
//       const uniqueId = new Date().getTime().toString();
//       const newBlockHTML = optionTemplateHTML.replace(/NEW_RECORD/g, uniqueId);

//       optionsContainer.insertAdjacentHTML("beforeend", newBlockHTML);
//     });
//   }

//   // Handle removal of options
//   if (optionsContainer) {
//     optionsContainer.addEventListener("click", (e) => {
//       console.log(e.target);
//       if (e.target.className == "remove-option") {
//         e.preventDefault();
//         const optionBlock = e.target.parentElement;
//         if (optionBlock.className == "option-field") {
//           const destroyField = optionBlock.querySelector("input[type='hidden'][name*='_destroy']");
//           console.log(destroyField);
//           if (destroyField) {
//             destroyField.value = "1";
//             optionBlock.style.display = "none";
//           }
//         }
//       }
//     });
//   }
// });
