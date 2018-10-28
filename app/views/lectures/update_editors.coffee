editorSelectize = document.getElementById('lecture_editor_ids').selectize
editorSelectize.addOption(<%= raw(@editor_selection) %>)
editorSelectize.refreshOptions(false)
editorSelectize.enable()
$('#lecture_editors_info').hide()
$('#lecture_editors_select').show()
$('#update-editors-button').hide()
