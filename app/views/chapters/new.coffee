$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return
$('#new-chapter-area').empty()
  .append('<%= j render partial: "chapters/new",
                        locals: { lecture: @lecture,
                                  chapter: @chapter} %>').show()
