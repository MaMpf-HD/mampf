# clean up from previous error messages
$('#assignment_title').removeClass('is-invalid')
$('#assignment-title-error').empty()
$('#assignment_deadline').removeClass('is-invalid')
$('#assignment-deadline-error').empty()

# display error message
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#assignment-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#assignment_title').addClass('is-invalid')
<% end %>
<% if @errors[:deadline].present? %>
$('#assignment-deadline-error')
  .append('<%= @errors[:deadline].join(" ") %>').show()
$('#assignment_deadline').addClass('is-invalid')
<% end %>
<% else %>
$('.assignmentRow[data-id="0"')
  .replaceWith('<%= j render partial: "assignments/row",
                      locals: { assignment: @assignment,
                      					inspection: false } %>')
$('#newAssignmentButton').show()
<% end %>