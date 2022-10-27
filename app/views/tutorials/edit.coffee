$('.tutorialRow[data-id="<%= @tutorial.id %>"')
  .replaceWith('<%= j render partial: "tutorials/form",
                      locals: { tutorial: @tutorial } %>')

fillOptionsByAjax($('#tutorial_tutor_ids_<%= @tutorial.id %>'))
