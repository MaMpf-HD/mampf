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

function constructDatePickerElement(index) {
  return `<div class="mt-2" id="talk_dates_${index}">
            <input type="date" name="talk[dates[${index}]]">
            <a class="fas fa-trash-alt clickable text-dark ms-2 remove-talk-date"
               data-index="${index}">
            </a>
          </div>`;
}

$(document).on("turbolinks:load", function () {
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

  $(document).on("click", "#new-talk-date-button", function () {
    const index = $(this).data("index");
    $("#talk-date-picker").append(constructDatePickerElement(index));
    $(this).data("index", index + 1);
    $("#talk-basics-warning").show();
  });

  $(document).on("click", ".remove-talk-date", function () {
    const index = $(this).data("index");
    $("#talk_dates_" + index).remove();
    $("#talk-basics-warning").show();
  });
});

$(document).on("turbolinks:before-cache", function () {
  $(document).off("change", "#talk-form :input");
  $(document).off("click", "#new-talk-date-button");
  $(document).off("click", ".remove-talk-date");
  $(document).off("click", "#cancel-talk-edit");
});
