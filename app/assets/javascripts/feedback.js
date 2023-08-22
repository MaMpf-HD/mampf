$(document).on('turbolinks:load', () => {
    registerToasts();
    registerSubmitButtonHandler();
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
