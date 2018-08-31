$('[id^="collapse-section-"]').collapse('hide')
$('#new-section-area').empty()
  .append('<%= j render partial: "sections/new",
                        locals: { section: @section,
                                  chapter: @chapter } %>').show()
$('#new_section_button').hide()
$('#cancel-new-section').on 'click', ->
  $('#new-section-area').empty().hide()
  $('#new_section_button').show()
  return
