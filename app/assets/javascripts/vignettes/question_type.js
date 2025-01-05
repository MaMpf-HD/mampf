document.addEventListener("turbolinks:load", () => {
  const questionTypeDropdown = document.getElementById("question-type");
  if (questionTypeDropdown) {
    questionTypeDropdown.addEventListener("change", function (event) {
      // Disable all fields by default
      const allQuestionFields = document.getElementsByClassName("question-field");
      for (let field of allQuestionFields) {
        field.style.display = "none";
      }
      // make selected field visible
      const selectedType = event.target.value;
      if (selectedType) {
        const selectedField = document.getElementById(selectedType);
        console.log(selectedField);
        if (selectedField) {
          selectedField.style.display = "block";
        }
      }
    });

    questionTypeDropdown.dispatchEvent(new Event("change"));
  };
  const optionsContainer = document.getElementById("options-container");

  // Handle dynamic addition of options
  const addOptionButton = document.getElementById("add-option");
  const optionTemplate = document.getElementById("new-option-template");
  if (addOptionButton) {
    addOptionButton.addEventListener("click", (e) => {
      const optionTemplateHTML = optionTemplate.innerHTML;
      const uniqueId = new Date().getTime().toString();
      const newBlockHTML = optionTemplateHTML.replace(/NEW_RECORD/g, uniqueId);

      optionsContainer.insertAdjacentHTML("beforeend", newBlockHTML);
    });
  }

  // Handle removal of options
  if (optionsContainer) {
    optionsContainer.addEventListener("click", (e) => {
      console.log(e.target);
      if (e.target.className == "remove-option") {
        e.preventDefault();
        const optionBlock = e.target.parentElement;
        if (optionBlock.className == "option-field") {
          const destroyField = optionBlock.querySelector("input[type='hidden'][name*='_destroy']");
          console.log(destroyField);
          if (destroyField) {
            destroyField.value = "1";
            optionBlock.style.display = "none";
          }
        }
      }
    });
  }
});
