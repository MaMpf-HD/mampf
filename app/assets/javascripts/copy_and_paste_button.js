$(document).on("turbolinks:load", function () {
  // TODO: this is using clipboard.js, which makes use of deprecated browser APIs
  // see issue #684
  new Clipboard(".clipboard-btn");

  $(document).on("click", ".clipboard-button", function () {
    $(".token-clipboard-popup").removeClass("show");

    const popupId = `.token-clipboard-popup[data-id="${$(this).data("id")}"]`;
    $(popupId).addClass("show");

    setTimeout(() => {
      $(popupId).removeClass("show");
    }, 1700);
  });
});

// clean up for turbolinks
$(document).on("turbolinks:before-cache", function () {
  $(document).off("click", ".clipboard-button");
});
