<% if @assignment.destroyed? %>
$('.assignmentRow[data-id="<%= @assignment.id %>"').remove()
<% if @lecture.assignments.none? %>
$('#assignmentListHeader').hide()
<% end %>
<% else %>
alert('<%= t("controllers.assignments.destruction_failed") %>')
<% end %>