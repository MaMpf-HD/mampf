$(document).on('turbolinks:load', () => {
    registerToasts();
    registerSubmitButtonHandler();
    registerFeedbackBodyValidator();
});

TOAST_OPTIONS = {
    animation: true,
    autohide: true,
    delay: 6000 // autohide after ... milliseconds
};

function registerToasts() {
    const toastElements = document.querySelectorAll('.toast');
    const toastList = [...toastElements].map(toast => {
        new bootstrap.Toast(toast, TOAST_OPTIONS);
    });
}

function registerSubmitButtonHandler() {
    $('#submit-form-btn-outside').click(() => {
        // Invoke the hidden submit button inside the actual Rails form
        $('#submit-form-btn').click();
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
