$(document).on("turbolinks:load", () => {
  if (!shouldRegisterFeedback()) {
    return;
  }
  registerToasts();
  registerSubmitButtonHandler();
  registerFeedbackBodyValidator();
});

const SUBMIT_FEEDBACK_ID = "#submit-feedback";

const TOAST_OPTIONS = {
  animation: true,
  autohide: true,
  delay: 6000, // autohide after ... milliseconds
};

function shouldRegisterFeedback() {
  return $(SUBMIT_FEEDBACK_ID).length > 0;
}

function registerToasts() {
  const toastElements = document.querySelectorAll(".toast");
  [...toastElements].map((toast) => {
    new bootstrap.Toast(toast, TOAST_OPTIONS);
  });
}

function registerSubmitButtonHandler() {
  // Invoke the hidden submit button inside the actual Rails form
  $("#submit-feedback-form-btn-outside").click(() => {
    submitFeedback();
  });

  // Submit form by pressing Ctrl + Enter
  document.addEventListener("keydown", (event) => {
    const isModalOpen = $(SUBMIT_FEEDBACK_ID).is(":visible");
    if (isModalOpen && event.ctrlKey && event.key == "Enter") {
      submitFeedback();
    }
  });
}

function registerFeedbackBodyValidator() {
  const feedbackBody = document.getElementById("feedback_feedback");
  feedbackBody.addEventListener("input", () => {
    validateFeedback();
  });
}

function validateFeedback() {
  const feedbackBody = document.getElementById("feedback_feedback");
  const validityState = feedbackBody.validity;
  if (validityState.tooShort) {
    const tooShortMessage = feedbackBody.dataset.tooShortMessage;
    feedbackBody.setCustomValidity(tooShortMessage);
  }
  else if (validityState.valueMissing) {
    const valueMissingMessage = feedbackBody.dataset.valueMissingMessage;
    feedbackBody.setCustomValidity(valueMissingMessage);
  }
  else {
    // render input valid, so that form will submit
    feedbackBody.setCustomValidity("");
  }

  feedbackBody.reportValidity();
}

function submitFeedback() {
  const submitButton = $("#submit-feedback-form-btn");
  validateFeedback();
  submitButton.click();
}
