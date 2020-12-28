$('.assignmentRow[data-id="<%= @assignment.id %>"')
  .replaceWith('<%= j render partial: "assignments/form",
                      locals: { assignment: @assignment } %>')

$('#assignment_medium_id_<%= @assignment.id %>').select2
  placeholder: '<%= t("basics.select") %>'
  allowClear: true
  language: '<%= I18n.locale %>'
  theme: 'bootstrap'

$("#assignment_deadline_<%= @assignment.id %>").datetimepicker
  format:'d.m.Y H:i'
  inline:false

<% unless @assignment.medium %>
# make sure that no medium is preselected
$('#assignment_medium_id_<%= @assignment.id %>').val(null).trigger('change')
<% end %>