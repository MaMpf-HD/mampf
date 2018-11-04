editorSelectize = document.getElementById('lecture_editor_ids').selectize
editorSelectize.addOption(<%= raw(@editor_selection) %>)
editorSelectize.refreshOptions(false)
editorSelectize.enable()
$('#lecture_editors_info').hide()
$('#lecture_editors_select').show()
$('#update-editors-button').hide()
# allow empty input (otherwise nothiung will be submitted, resulting in
# no change at all)
$('input[name="lecture[editor_ids][]"]').removeAttr('disabled');
