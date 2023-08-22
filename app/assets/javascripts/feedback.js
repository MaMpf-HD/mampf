$(document).on('turbolinks:load', () => {
    registerToasts();
    registerSubmitButtonHandler();
});

TOAST_OPTIONS = {
    animation: true,
    autohide: true,
    delay: 6000 // autohide after 5s
};

function registerToasts() {
    const toastElements = document.querySelectorAll('.toast');
    console.log(toastElements);
    const toastList = [...toastElements].map(toast => {
        new bootstrap.Toast(toast, TOAST_OPTIONS);
    });
}

function registerSubmitButtonHandler() {
    $('#submit-form-btn-outside').click(() => {
        $('#submit-form-btn').click();
    });
}
