$('#new-lecture-area').empty()
  .append('<%= j render partial: "lectures/new",
                        locals: { lecture: @lecture,
                                  from: @from } %>').show()
$('#new-lecture-area .selectize').selectize({ plugins: ['remove_button'] })
$('.admin-index-button').hide()
teacherSelector = document.getElementById('lecture_teacher_id')
sel = teacherSelector.selectize
sel.on 'blur', ->
  value = sel.getValue()
  if value == ''
    sel.setValue(teacherSelector.dataset.current)
  return
<% if @from == 'course' %>
$('#newLectureModal').modal('show')
<% end %>
