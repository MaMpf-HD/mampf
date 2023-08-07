$(document).on('turbolinks:load', registerSubmitButtonHandler);

function registerSubmitButtonHandler() {
    $('#submit-form-btn-outside').click(() => {
        $('#submit-form-btn').click();
    });
}
