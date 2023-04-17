document.addEventListener("turbolinks:load", () => {
    if (window.location.hash == "#sponsors") {
        $('#sponsors').modal('show');
    }

    $('#sponsorsLink').click(function (event) {
        window.history.pushState(null, null, '#sponsors');
    });

    $('#sponsors').on('hide.bs.modal', () => {
        window.history.pushState(null, null, location.pathname);
    });
});
