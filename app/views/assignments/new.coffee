$('#newAssignmentButton').hide()
$('#assignmentListHeader').show()
  .after('<%= j render partial: "assignments/form",
                       locals: { assignment: @assignment } %>')

new TomSelect('#assignment_medium_id_',
  sortField:
    field: 'text'
    direction: 'asc'
  render:
    no_results: (data, escape) ->
      '<div class="no-results"><%= t("basics.no_results") %></div>'
)

# make sure that no medium is preselected
$('#assignment_medium_id_').val(null).trigger('change')

$("#assignment_deadline_").datetimepicker
  format:'d.m.Y H:i'
  inline:false