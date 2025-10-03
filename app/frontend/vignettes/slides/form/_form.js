import TomSelect from "tom-select";

$(document).on("turbo:frame-render", function () {
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
