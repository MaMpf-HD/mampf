$('#assignmentListHeader').show()
  .after('<%= j render partial: "assignments/form",
                       locals: { assignment: @assignment } %>')

$('#assignment_medium_id').select2
  placeholder: '<%= t("basics.select") %>'
  allowClear: true
  language: '<%= I18n.locale %>'
  theme: 'bootstrap'

# make sure that no medium is preselected
$('#assignment_medium_id').val(null).trigger('change')
