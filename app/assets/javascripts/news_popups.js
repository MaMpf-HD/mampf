console.log('loaded');

// <input class="form-control" value="<%= popup.name %>">


$(document).on('turbolinks:load', () => {
    registerNewsPopupsAdminTableHandlers();
});

function registerNewsPopupsAdminTableHandlers() {
    $('.news-popups-name').on('click', (e) => {
        // If has input, do nothing
        if ($(e.target).find('input').length > 0) {
            return;
        }

        const rowId = $(e.target).parent().attr('id').split('-').pop();
        console.log('rowId: ' + rowId);

        const text = $(e.target).text().trim();
        const inputHtml = `<input class="form-control news-popups-name-current" value="${text}">`;
        $(e.target).html(inputHtml);

        $('.news-popups-name-current').focus();
    });


    console.log('admin table registered');
}