$('#tag_title').removeClass('is-invalid')
$('#tag-title-error').empty()
$('#tag-additional-lectures-error').empty()
$('#tag-disabled-lectures-error').empty()
$('#tag-courses-error').empty()
$('#tag-related-tags-error').empty()
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#tag-title-error').append('<%= @errors[:title].join(", ") %>').show()
$('#tag_title').addClass('is-invalid')
<% end %>
<% if @errors[:additional_lectures].present? %>
$('#tag-additional-lectures-error').append('<%= @errors[:additional_lectures].join(" ") %>')
  .show()
<% end %>
<% if @errors[:disabled_lectures].present? %>
$('#tag-disabled-lectures-error').append('<%= @errors[:disabled_lectures].join(" ") %>')
  .show()
<% end %>
<% if @errors[:courses].present? %>
$('#tag-courses-error').append('<%= @errors[:courses].join(" ") %>')
  .show()
<% end %>
<% if @errors[:related_tags].present? %>
$('#tag-related-tags-error').append('<%= @errors[:related_tags].join(" ") %>')
  .show()
<% end %>
<% else %>
location.reload()
<% end %>
