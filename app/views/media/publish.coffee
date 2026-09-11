# clean up from previous error messages
$('#release-date-error').empty()
$('#release_date').removeClass('is-invalid')
$('#assignment-deadline-error').empty()
$('#medium_assignment_deadline').removeClass('is-invalid')
$('#assignment-title-error').empty()
$('#medium_assignment_title').removeClass('is-invalid')

# display error message
<% if @errors[:release_date].present? %>
$('#release-date-error').append('<%= @errors[:release_date] %>')
  .show()
$('#release_date').addClass('is-invalid')
<% end %>

<% if @errors[:assignment_deadline].present? %>
$('#assignment-deadline-error').append('<%= @errors[:assignment_deadline] %>')
  .show()
$('#medium_assignment_deadline').addClass('is-invalid')
<% end %>

<% if @errors[:assignment_title].present? %>
$('#assignment-title-error').append('<%= @errors[:assignment_title] %>')
  .show()
$('#medium_assignment_title').addClass('is-invalid')
<% end %>