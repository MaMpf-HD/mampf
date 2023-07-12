<% if @errors.present? %>
# clean up from previous error messages
$('#assignment_title_').removeClass('is-invalid')
$('#assignment-title-error').empty()

# display error message
<% if @errors[:title].present? %>
$('#assignment-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#assignment_title_').addClass('is-invalid')
<% end %>
<% if @errors[:deadline].present? %>
$('#assignment-deadline-error')
  .append('<%= @errors[:deadline].join(" ") %>').show()
$('#assignment_deadline').addClass('is-invalid')
<% end %>
<% if @errors[:deletion_date].present? %>
$('#assignment-deletion-date-error')
  .append('<%= @errors[:deletion_date].join(" ") %>').show()
$('#assignment_deletion_date').addClass('is-invalid')
<% end %>
<% else %>
$('.assignmentRow[data-id="<%= @assignment.id %>')
  .replaceWith('<%= j render partial: "assignments/row",
                      locals: { assignment: @assignment } %>')
<% end %>