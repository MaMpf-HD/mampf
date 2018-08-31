$('#new-section-area').empty()
  .append('<%= j render partial: "sections/new",
                        locals: { section: @section,
                                  chapter: @chapter } %>').show()
$('#new_section_button').hide()
