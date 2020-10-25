$('.tutorialRow[data-id="<%= @tutorial.id %>')
  .replaceWith('<%= j render partial: "tutorials/row",
                      locals: { tutorial: @tutorial,
                      					inspection: false } %>')