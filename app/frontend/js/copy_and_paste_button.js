import Clipboard from "clipboard";

$(document).on("turbo:load", function () {
  // TODO: this is using clipboard.js, which makes use of deprecated browser APIs
  // see issue #684
  new Clipboard(".clipboard-btn");

  $(document).on("click", ".clipboard-button", function () {
    $(".token-clipboard-popup").removeClass("show");

    const dataId = $(this).data("id");
    let popup;
    if (dataId) {
      popup = `.token-clipboard-popup[data-id="${$(this).data("id")}"]`;
    }
    else {
      // This is a workaround for the transition to the new ClipboardAPI
      // as intermediate solution that respects that the whole button should
      // be clickable, not just the icon itself.
      // See app/views/vouchers/_voucher.html.erb as an example.
      popup = $(this).find(".token-clipboard-popup");
    }

    $(popup).addClass("show");
    setTimeout(() => {
      $(popup).removeClass("show");
    }, 1700);
  });
});

$(document).on("turbo:before-cache", function () {
  $(document).off("click", ".clipboard-button");
});
