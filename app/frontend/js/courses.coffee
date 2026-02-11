$(document).on 'turbo:load', ->
  # after creation of new lecture is cancelled,
  # reload the page (if that happended on the course edit page) or
  # clean the page up (if it happened on the admin index page)
  $(document).on 'click', '#cancel-new-lecture', ->
    if $('#course_preceding_course_ids').length == 1
      location.reload(true)
    else
      $('#new-lecture-area').empty().hide()
      $('.admin-index-button').show()
    return

$(document).on 'turbo:before-cache', ->
  $(document).off 'click', '#cancel-new-lecture'
  return
