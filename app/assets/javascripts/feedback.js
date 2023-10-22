$(document).on('turbolinks:load', () => {
    if (!shouldRegisterFeedback()) {
        return;
    }
    registerToasts();
    registerSubmitButtonHandler();
    registerFeedbackBodyValidator();
});

SUBMIT_FEEDBACK_ID = '#submit-feedback';

TOAST_OPTIONS = {
    animation: true,
    autohide: true,
    delay: 6000 // autohide after ... milliseconds
};

function shouldRegisterFeedback() {
    return $(SUBMIT_FEEDBACK_ID).length > 0;
}

function registerToasts() {
    const toastElements = document.querySelectorAll('.toast');
    const toastList = [...toastElements].map(toast => {
        new bootstrap.Toast(toast, TOAST_OPTIONS);
    });
}

function registerSubmitButtonHandler() {
    const submitButton = $('#submit-form-btn');

    // Invoke the hidden submit button inside the actual Rails form
    $('#submit-form-btn-outside').click(() => {
        submitButton.click();
    });

    // Submit form by pressing Ctrl + Enter
    document.addEventListener('keydown', (event) => {
        const isModalOpen = $(SUBMIT_FEEDBACK_ID).is(':visible');
        if (isModalOpen && event.ctrlKey && event.key == "Enter") {
            submitButton.click();
        }
    });
}

function registerFeedbackBodyValidator() {
    const feedbackBody = document.getElementById('feedback_feedback');
    feedbackBody.addEventListener('input', () => {
        if (feedbackBody.validity.tooShort) {
            const tooShortMessage = feedbackBody.dataset.tooShortMessage;
            feedbackBody.setCustomValidity(tooShortMessage);
        } else {
            // render input valid, so that form will submit
            feedbackBody.setCustomValidity('');
        }
    });
}
