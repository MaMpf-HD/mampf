import TomSelect from "tom-select";

$(document).on("turbo:load turbo:frame-load", function () {
  document.querySelectorAll(".vignettes-linked-info-slides:not(.ts-wrapper)")
    .forEach((element) => {
      if (element.tomselect) {
        return;
      }

      new TomSelect(element, {
        plugins: ["remove_button"],
      });
    });
});
