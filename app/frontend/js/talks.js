function renderMath(element) {
  renderMathInElement(element, {
    delimiters: [
      {
        left: "$$",
        right: "$$",
        display: true,
      },
      {
        left: "$",
        right: "$",
        display: false,
      },
      {
        left: "\\(",
        right: "\\)",
        display: false,
      },
      {
        left: "\\[",
        right: "\\]",
        display: true,
      },
    ],
    throwOnError: false,
  });
}

window.previewTrixTalkContent = function (trixElement) {
  trixElement = document.querySelector(trixElement);
  if (!trixElement) {
    return;
  }

  const { content } = trixElement.dataset;
  const { preview } = trixElement.dataset;
  const { editor } = trixElement;
  if (!editor) {
    return;
  }

  editor.setSelectedRange([0, 65535]);
  editor.deleteInDirection("forward");
  editor.insertHTML(content);
  document.activeElement.blur();

  return trixElement.addEventListener("trix-change", function () {
    $("#talk-basics-warning").show();
    $("#" + preview).html($(this).html());
    const previewBox = document.getElementById(preview);
    renderMath(previewBox);
  });
};

function handleDateSelection() {
  // Adding
  $(document).on("click", "#new-talk-date-button", function () {
    const newIndex = $(this).data("index");
    $(this).data("index", newIndex + 1); // next index if clicked again

    const template = $("#talk-date-template");
    const newDateHtml = template.html().replace(/NEW_RECORD/g, newIndex);
    $("#talk-dates").append(newDateHtml);

    $("#talk-basics-warning").show();
  });

  // Removing
  $(document).on("click", ".remove-talk-date", function (evt) {
    $(evt.target).closest("div").remove();
    $("#talk-basics-warning").show();
  });
}

$(document).on("turbo:load", function () {
  $(document).on("change", "#talk-form :input", function () {
    $("#talk-basics-warning").show();
  });

  $(document).on("click", "#cancel-talk-edit", function () {
    location.reload(true);
  });

  $(document).on("click", "#cancel-talk-assemble", function () {
    location.reload(true);
  });

  previewTrixTalkContent("#talk-details-trix");
  previewTrixTalkContent("#talk-description-trix");

  handleDateSelection();
});

$(document).on("turbolinks:before-cache", function () {
  $(document).off("change", "#talk-form :input");
  $(document).off("click", "#new-talk-date-button");
  $(document).off("click", ".remove-talk-date");
  $(document).off("click", "#cancel-talk-edit");
});
