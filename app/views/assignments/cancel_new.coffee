$('.assignmentRow[data-id="0"]').remove()
<% if @none_left %>
$('#assignmentListHeader').hide()
<% end %>
$('#newAssignmentButton').show()