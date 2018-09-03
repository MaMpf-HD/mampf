$('#new-lesson-modal-content').empty()
  .append('<%= j render partial: "lessons/modal_wrap",
                        locals: { lesson: @lesson,
                                  from: @from,
                                  section: @section,
                                  inspection: false }%>')
$('#new-lesson-modal-content .selectize').selectize({ plugins: ['remove_button'] })
$('#newLessonModal').modal('show').data('from','<%= @from %>')
