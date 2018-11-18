# update editor selection
editorSelectize = document.getElementById('lecture_editor_ids').selectize
editorSelectize.addOption(<%= raw(@editor_selection) %>)
editorSelectize.refreshOptions(false)
editorSelectize.enable()

# hide some buttons, show editor select field
$('#lecture_editors_info').hide()
$('#lecture_editors_select').show()
$('#update-editors-button').hide()

# allow empty input (otherwise nothing will be submitted, resulting in
# no change at all)
$('input[name="lecture[editor_ids][]"]').removeAttr('disabled');
