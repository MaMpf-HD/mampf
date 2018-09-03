if $('#lecture-basics-warning').is(':visible')
  $('#no-effect-warning').show()
else
  $('#new-chapter-area').empty()
    .append('<%= j render partial: "chapters/new",
                          locals: { lecture: @lecture,
                                    chapter: @chapter} %>').show()
  $('#new_chapter_button').hide()
  $('[id^="new_section_button"]').hide()
  $('#new_lesson_button').hide()
  $('#cancel-new-chapter').on 'click', ->
    $('#new-chapter-area').empty().hide()
    $('#new_chapter_button').show()
    $('#new_lesson_button').show()
    $('[id^="new_section_button"]').show()
    return
