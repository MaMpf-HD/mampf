$(document).on('turbolinks:load', () => {
    $('#submit-form-btn-outside').click(() => {
        console.log('click');
        $('#submit-form-btn').click();
    });
});
