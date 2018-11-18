# update teacher selection
teacherSelectize = document.getElementById('lecture_teacher_id').selectize
teacherSelectize.addOption(<%= raw(@teacher_selection) %>)
teacherSelectize.refreshOptions(false)
teacherSelectize.enable()

# hide some butttons, show teacher select field
$('#lecture_teacher_info').hide()
$('#lecture_teacher_select').show()
$('#update-teacher-button').hide()
