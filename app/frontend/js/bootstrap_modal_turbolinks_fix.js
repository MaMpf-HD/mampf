$(document).on("turbo:load", function () {
  $(".activeModal").modal("show");
  $(".activeModal").removeClass("activeModal");
});

$(document).on("turbo:before-cache", function () {
  if ($("body").hasClass("modal-open")) {
    $(".modal.show").addClass("activeModal");
    $(".modal.show").modal("hide");
    $(".modal-backdrop").remove();
  }
});
