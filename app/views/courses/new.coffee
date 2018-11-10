$('#new-course-area').empty()
  .append('<%= j render partial: "courses/new",
                        locals: { course: @course } %>').show()
$('#new-course-area .selectize').selectize({ plugins: ['remove_button'] })
$('[data-toggle="popover"]').popover()
$('.admin-index-button').hide()
$('#cancel-new-course').on 'click', ->
  $('#new-course-area').empty().hide()
  $('#new-course-button').show()
  $('.admin-index-button').show()
  return
