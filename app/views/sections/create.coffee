$('#new_section_title').removeClass('is-invalid')
$('#new-section-title-error').empty()
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#new-section-title-error')
  .append('<%= @errors[:title].join(" ") %>').show()
$('#new_section_title').addClass('is-invalid')
<% end %>
<% end %>
