# clean up from previous error messages
$('#new_section_title').removeClass('is-invalid')
$('#new-section-title-error').empty()

# display error message
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#new-section-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#new_section_title').addClass('is-invalid')
<% end %>
<% else %>
location.reload()
<% end %>
