$('#newTutorialButton').hide()
$('#tutorialListHeader').show()
  .after('<%= j render partial: "tutorials/form",
                       locals: { tutorial: @tutorial } %>')
fillOptionsByAjax($('#tutorial_tutor_ids_'))
