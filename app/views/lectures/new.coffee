# render new lecture partial to the corresponding area,
# activate selectize and popovers
$('#new-lecture-area').empty()
  .append('<%= j render partial: "lectures/new",
                        locals: { lecture: @lecture,
                                  from: @from } %>').show()
$('#new-lecture-area .selectize').selectize({ plugins: ['remove_button'] })
$('[data-toggle="popover"]').popover()

# hide all other buttons on admin index page
$('.admin-index-button').hide()

# make sure that there will always be a teacher selected
teacherSelector = document.getElementById('lecture_teacher_id')
sel = teacherSelector.selectize
sel.on 'blur', ->
  value = sel.getValue()
  if value == ''
    sel.setValue(teacherSelector.dataset.current)
  return

# show the modal if the new action was triggered from course edit page
<% if @from == 'course' %>
$('#newLectureModal').modal('show')
<% end %>
