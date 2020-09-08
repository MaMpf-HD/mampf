$('#tutorialListHeader')
  .after('<%= j render partial: "tutorials/form",
                       locals: { tutorial: @tutorial } %>')