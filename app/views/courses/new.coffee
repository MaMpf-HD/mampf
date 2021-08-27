# render new course partial to the corresponding area,
# activate selectize and popovers
$('#new-course-area').show()

# restore page if creation of new course is cancelled
$('#cancel-new-course').on 'click', ->
  $('#new-course-area').empty().hide()
  $('#new-course-button').show()
  $('.admin-index-button').show()
  return
