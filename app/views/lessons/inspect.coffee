# render inspect lesson modal
$('#lesson-action').empty().append('ansehen')
$('#lesson-modal-content').empty()
  .append('<%= j render partial: "lessons/basics",
                        locals: { lesson: @lesson,
                                  inspection: true,
                                  modal: true } %>').show()
$('#lessonModal').modal('show')

#activate popovers
$('[data-toggle="popover"]').popover()
