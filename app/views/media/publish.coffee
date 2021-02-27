# clean up from previous error messages
$('#release-date-error').empty()
$('#release_date').removeClass('is-invalid')

# display error message
<% if @errors[:release_date].present? %>
$('#release-date-error').append('<%= @errors[:release_date] %>')
  .show()
$('#release_date').addClass('is-invalid')
<% end %>