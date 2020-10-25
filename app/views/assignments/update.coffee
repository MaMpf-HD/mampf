<% if @errors.present? %>
# clean up from previous error messages
$('#assignment_title').removeClass('is-invalid')
$('#assignment-title-error').empty()

# display error message
<% if @errors[:title].present? %>
$('#assignment-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#assignment_title').addClass('is-invalid')
<% end %>

<% else %>
$('.assignmentRow[data-id="<%= @assignment.id %>')
  .replaceWith('<%= j render partial: "assignments/row",
                      locals: { assignment: @assignment,
                      					inspection: false } %>')
<% end %>