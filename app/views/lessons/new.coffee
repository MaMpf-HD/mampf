$('#new-lesson-area').empty()
  .append('<%= j render partial: "lessons/new",
                        locals: { lesson: @lesson } %>').show()
$('#new-lesson-area .selectize').selectize({ plugins: ['remove_button'] })
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-preferences-form input').prop('disabled', true) 
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return
