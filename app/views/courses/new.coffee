# render new course partial to the corresponding area,
# activate selectize and popovers
$('#new-course-area').show()
#   .append('<%= j render partial: "courses/new",
#                         locals: { course: @course } %>').show()
# $('#new-course-area .selectize').selectize({ plugins: ['remove_button'] })
# $('[data-toggle="popover"]').popover()

# hide all other buttons on admin index page
# $('.admin-index-button').hide()

# restore page if creation of new course is cancelled
$('#cancel-new-course').on 'click', ->
  $('#new-course-area').empty().hide()
  $('#new-course-button').show()
  $('.admin-index-button').show()
  return
