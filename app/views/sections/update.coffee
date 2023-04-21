# clean up from previous error messages
$('#section_title_<%= @section.id.to_i %>').removeClass('is-invalid')
$('#section-title-error-<%= @section.id.to_i %>').empty()
$('#section-tags-error-<%= @section.id.to_i %>').empty()
$('#section-lessons-error-<%= @section.id.to_i %>').empty()

# display error messages
<% if @errors[:title].present? %>
$('#section-title-error-<%= @section.id.to_i %>')
  .append('<%= @errors[:title].join(", ") %>').show()
$('#section_title_<%= @section.id.to_i %>').addClass('is-invalid')
<% end %>
