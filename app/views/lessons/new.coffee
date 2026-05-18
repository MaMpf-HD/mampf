# render new lesson form
$('#lesson-modal-content').empty()
  .append('<%= j render partial: "lessons/new",
                        locals: { lesson: @lesson } %>').show()
$('#lesson-modal-content .selectize').each ->
  new TomSelect("#"+this.id,{ plugins: ['remove_button'] })
$('#lessonModal').modal('show')
initBootstrapPopovers()
