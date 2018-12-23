<% if @errors.present? %>
$('#announcement-error').empty().append('<%= @errors %>').show()
$('#announcement_details').addClass('is-invalid')
<% else %>
location.reload()
<% end %>