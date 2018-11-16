# disable all other input fields when a new chapter is created
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return
$('#lecture-preferences-form input').prop('disabled', true)

# render new chapter form
$('#new-chapter-area').empty()
  .append('<%= j render partial: "chapters/new",
                        locals: { lecture: @lecture,
                                  chapter: @chapter} %>').show()
$('[data-toggle="popover"]').popover()
