$('#newAssignmentButton').hide()
$('#assignmentListHeader').show()
  .after('<%= j render partial: "assignments/form",
                       locals: { assignment: @assignment } %>')

$("#assignment_deadline_").datetimepicker
  format:'d.m.Y H:i'
  inline:false

$('#assignment_medium_id_').select2
  placeholder: '<%= t("basics.select") %>'
  allowClear: true
  language: '<%= I18n.locale %>'
  theme: 'bootstrap'

# make sure that no medium is preselected
$('#assignment_medium_id_').val(null).trigger('change')
