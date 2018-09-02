if $('#lecture-basics-warning').is(':visible')
  $('#no-effect-warning').show()
else
  $('#new-lesson-area').empty()
    .append('<%= j render partial: "lessons/new",
                          locals: { lesson: @lesson } %>').show()
  $('#new-lesson-area .selectize').selectize()
  $('#new_lesson_button').hide()
  $('#new_chapter_button').hide()
  $('#cancel-new-lesson').on 'click', ->
    $('#new-lesson-area').empty().hide()
    $('#new_lesson_button').show()
    $('#new_chapter_button').show()
    return
