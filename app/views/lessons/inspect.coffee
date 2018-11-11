$('#lesson-action').empty().append('ansehen')
$('#lesson-modal-content').empty()
  .append('<%= j render partial: "lessons/basics",
                        locals: { lesson: @lesson,
                                  inspection: true,
                                  modal: true } %>').show()
$('#lessonModal').modal('show')
$('[data-toggle="popover"]').popover()
