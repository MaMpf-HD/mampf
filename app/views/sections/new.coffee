$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return
$('#new-section-area-<%= @chapter.id %>').empty()
  .append('<%= j render partial: "sections/new",
                        locals: { section: @section,
                                  chapter: @chapter } %>').show()
