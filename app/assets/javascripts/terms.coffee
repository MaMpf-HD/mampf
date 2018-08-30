$(document).on 'turbolinks:load', ->

  $(document).on 'click', '#cancel-term-edit', ->
    term = this.dataset.term
    new_action = this.dataset.new
    $.ajax Routes.cancel_term_edit_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: term
        new: new_action
      }
    return
  return
