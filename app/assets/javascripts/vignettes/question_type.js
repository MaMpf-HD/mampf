var questionTypeHTML = {
  TextQuestion: `
    <div>
        <%= form.label :question_text, "Question Text" %><br>
        <%= form.text_area :question_text %>
    </div> 
    `,
};
document.addEventListener("turbolinks:load", () => {
  const questionTypeDropdown = document.getElementById("question_type");
  const questionField = document.getElementById("question_field");
  if (questionTypeDropdown && questionField) {
    questionTypeDropdown.addEventListener("change", function (event) {
      const selectedType = event.target.value;
      if (selectedType == "") {
        questionField.innerHTML = "";
        return;
      }
      else {
        questionField.innerHTML = questionTypeHTML[selectedType];
      }
    });
  };
});
