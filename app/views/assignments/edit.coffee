$('.assignmentRow[data-id="<%= @assignment.id %>"')
  .replaceWith('<%= j render partial: "assignments/form",
                      locals: { assignment: @assignment } %>')

new TomSelect('#assignment_medium_id_<%= @assignment.id %>',
  sortField:
    field: 'text'
    direction: 'asc'
  render:
    no_results: (data, escape) ->
      '<div class="no-results"><%= t("basics.no_results") %></div>'
)

<% unless @assignment.medium %>
# make sure that no medium is preselected
$('#assignment_medium_id_<%= @assignment.id %>').val(null).trigger('change')
<% end %>

# using moment to format the date right
d = moment($("#assignment_deadline_<%= @assignment.id %>").val(),"YYYY-MM-DD hh:mm:ss z")
$("#assignment_deadline_<%= @assignment.id %>").val (d.format("DD.MM.Y H:mm"))
$("#assignment_deadline_<%= @assignment.id %>").datetimepicker
  format:'d.m.Y H:i'
  inline:false
