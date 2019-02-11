# render new term row
$('#row-new-term').append('<%= j render partial: "terms/form",
                                        locals: { term: @term,
                                                  new_action: true } %>')
  .show()

# hide "new term" button
$('#create-new-term').hide()
