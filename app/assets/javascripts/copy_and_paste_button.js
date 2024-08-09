$(document).on("turbolinks:load", function () {
  new Clipboard(".clipboard-btn");

  $(document).on("click", ".clipboard-button", function () {
    $(".token-clipboard-popup").removeClass("show");
    var id = $(this).data("id");
    $('.token-clipboard-popup[data-id="' + id + '"]').addClass("show");

    var restoreClipboardButton = function () {
      $('.token-clipboard-popup[data-id="' + id + '"]').removeClass("show");
    };

    setTimeout(restoreClipboardButton, 1500);
  });
});

// clean up for turbolinks
$(document).on("turbolinks:before-cache", function () {
  $(document).off("click", ".clipboard-button");
});
