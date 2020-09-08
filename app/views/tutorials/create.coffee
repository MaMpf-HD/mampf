$('.tutorialRow[data-id="0"')
  .replaceWith('<%= j render partial: "tutorials/row",
                      locals: { tutorial: @tutorial } %>')