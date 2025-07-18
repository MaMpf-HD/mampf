$(document).on 'turbolinks:load', ->

  # restore site after editing of term was cancelled (via ajax)
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

# clean up before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#cancel-term-edit'
  return
