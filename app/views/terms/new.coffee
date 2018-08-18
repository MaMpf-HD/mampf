$('#row-new-term').append('<%= j render partial: "terms/form",
                                        locals: { term: @term,
                                                  new_action: true } %>')
  .show()
$('#create-new-term').hide()
