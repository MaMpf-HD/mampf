$(document).on 'click', 'cancel-term-edit', ->
  term = this.dataset.term
  $.ajax Routes.cancel_term_edit_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      term: term
    }
  return
