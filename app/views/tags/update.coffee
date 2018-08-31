$('#tag_title_<%= @tag.id.to_i %>').removeClass('is-invalid')
$('#tag-title-error-<%= @tag.id.to_i %>').empty()
$('#tag-additional-lectures-error-<%= @tag.id.to_i %>').empty()
$('#tag-disabled-lectures-error-<%= @tag.id.to_i %>').empty()
$('#tag-courses-error-<%= @tag.id.to_i %>').empty()
$('#tag-related-tags-error-<%= @tag.id.to_i %>').empty()
<% if @errors.present? %>
<% if @errors[:title].present? %>
$('#tag-title-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:title].join(", ") %>').show()
$('#tag_title_<%= @tag.id.to_i %>').addClass('is-invalid')
<% end %>
<% if @errors[:additional_lectures].present? %>
$('#tag-additional-lectures-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:additional_lectures].join(" ") %>').show()
<% end %>
<% if @errors[:disabled_lectures].present? %>
$('#tag-disabled-lectures-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:disabled_lectures].join(" ") %>').show()
<% end %>
<% if @errors[:courses].present? %>
$('#tag-courses-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:courses].join(" ") %>').show()
<% end %>
<% if @errors[:related_tags].present? %>
$('#tag-related-tags-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:related_tags].join(" ") %>').show()
<% end %>
<% else %>
<% if @modal %>
$('#newTagModal').modal('hide')
if $('#newTagModal').data('from') == 'section'
  tagSelector = document.getElementById('section_tag_ids_<%= @section.id.to_i %>').selectize
  tagSelector.addOption({ value: <%= @tag.id %>, text: '<%= @tag.title %>'})
  tagSelector.refreshOptions()
  values = tagSelector.getValue()
  values.push('<%= @tag.id %>')
  tagSelector.setValue(values)
else
  location.reload()
<% end %>
<% end %>
