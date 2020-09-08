$('.tutorialRow[data-id="<%= @tutorial.id %>"')
  .replaceWith('<%= j render partial: "tutorials/form",
                      locals: { tutorial: @tutorial } %>')