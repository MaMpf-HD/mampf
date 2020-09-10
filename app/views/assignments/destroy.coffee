$('.assignmentRow[data-id="<%= @assignment.id %>"').remove()
<% if @lecture.assignments.none? %>
$('#assignmentListHeader').hide()
<% end %>