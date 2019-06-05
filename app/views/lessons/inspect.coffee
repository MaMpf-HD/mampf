# render inspect lesson modal
$('#lesson-action').empty().append(I18n.t('admin.lesson.inspect'))
$('#lesson-modal-content').empty()
  .append('<%= j render partial: "lessons/basics",
                        locals: { lesson: @lesson,
                                  inspection: true,
                                  modal: true } %>').show()
$('#lessonModal').modal('show')

#activate popovers
$('[data-toggle="popover"]').popover()
