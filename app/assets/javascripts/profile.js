$(document).on("turbolinks:load", function () {
  $("#request-data-btn").on("click", function () {
    console.log("pressed");
    const toast = $("#request-data-toast");
    bootstrap.Toast.getOrCreateInstance(toast).show();
  });
});
