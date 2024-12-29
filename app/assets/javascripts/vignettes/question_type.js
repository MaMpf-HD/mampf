document.addEventListener("turbolinks:load", () => {
  const questionTypeDropdown = document.getElementById("question_type");
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
  };
});
