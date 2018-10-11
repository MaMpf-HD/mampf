$('#new-lecture-area').empty()
  .append('<%= j render partial: "lectures/new",
                        locals: { lecture: @lecture } %>').show()
$('#new-lecture-area .selectize').selectize({ plugins: ['remove_button'] })
$('#new-lecture-button').hide()
$('#cancel-new-lecture').on 'click', ->
  $('#new-lecture-area').empty().hide()
  $('#new-lecture-button').show()
  return
teacherSelector = document.getElementById('lecture_teacher_id')
sel = teacherSelector.selectize
sel.on 'blur', ->
  value = sel.getValue()
  if value == ''
    sel.setValue(teacherSelector.dataset.current)
  return
