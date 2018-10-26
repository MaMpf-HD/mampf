if $('#lecture-basics-warning').is(':visible')
  $('#no-effect-warning').show()
else
  $('#new-lesson-area').empty()
    .append('<%= j render partial: "lessons/new",
                          locals: { lesson: @lesson } %>').show()
  $('#new-lesson-area .selectize').selectize({ plugins: ['remove_button'] })
  $('#new_lesson_button').hide()
  $('#new_chapter_button').hide()
  $('[id^="new_section_button"]').hide()
  $('#lecture-form input').prop('disabled', true)
  $('#lecture-form .selectized').each ->
    this.selectize.disable()
    return
