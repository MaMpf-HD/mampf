document.addEventListener("turbolinks:load", () => {
    if (window.location.hash == "#sponsors") {
        $('#sponsors').modal('show');
    }
});
