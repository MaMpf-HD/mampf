document.addEventListener("turbolinks:load", function () {
    if (window.location.hash == "#sponsors") {
        $('#sponsors').modal('show');
    }

    $('#sponsors').on('hide.bs.modal', () => {
        window.history.pushState(null, null, location.pathname);
    });
});
