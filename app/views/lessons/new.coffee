# render new lesson form
$('#lesson-modal-content').empty()
  .append('<%= j render partial: "lessons/new",
                        locals: { lesson: @lesson } %>').show()
$('#lesson-modal-content .selectize').selectize({ plugins: ['remove_button'] })

# activate popovers
$('[data-toggle="popover"]').popover()

$('#lessonModal').modal('show')