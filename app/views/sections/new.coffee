if $('#lecture-basics-warning').is(':visible')
  $('#no-effect-warning').show()
else
  $('[id^="collapse-section-"]').collapse('hide')
  $('#new-section-area-<%= @chapter.id %>').empty()
    .append('<%= j render partial: "sections/new",
                          locals: { section: @section,
                                    chapter: @chapter } %>').show()
  $('#section_from').val($('#new_section_button_<%= @chapter.id %>')
    .data('from'))
  $('[id^="new_section_button"]').hide()
  $('#new_chapter_button').hide()
  $('#new_lesson_button').hide()
  $('#cancel-new-section-<%= @chapter.id %>').on 'click', ->
    $('#new-section-area-<%= @chapter.id %>').empty().hide()
    $('[id^="new_section_button"]').show()
    $('#new_lesson_button').show()
    $('#new_chapter_button').show()
    return
