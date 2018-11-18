# render new lesson form
$('#new-lesson-area').empty()
  .append('<%= j render partial: "lessons/new",
                        locals: { lesson: @lesson } %>').show()
$('#new-lesson-area .selectize').selectize({ plugins: ['remove_button'] })

# activate popovers
$('[data-toggle="popover"]').popover()

# disable all other input fields when a new lesson is being created
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-preferences-form input').prop('disabled', true)
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return
