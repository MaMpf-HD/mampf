function handleQuestionTypes() {
  const questionTypeDropdown = $("#vignettes-question-type");

  questionTypeDropdown.on("change", function (event) {
    const questionFields = $(".vignette-question-field");
    questionFields.each(function () {
      $(this).hide();
    });

    if (event.target.value === "") {
      // No question type selected
      return;
    }

    const selectedField = $("#" + event.target.value);
    if (selectedField) {
      selectedField.show();
    }
  });
}

handleQuestionTypes();

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
