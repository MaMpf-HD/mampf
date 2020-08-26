# clean up from previous error messages
$('#tag_title_<%= @tag.id.to_i %>').removeClass('is-invalid')
$('#tag-title-error-<%= @tag.id.to_i %>').empty()
$('#tag-additional-lectures-error-<%= @tag.id.to_i %>').empty()
$('#tag-disabled-lectures-error-<%= @tag.id.to_i %>').empty()
$('#tag-courses-error-<%= @tag.id.to_i %>').empty()
$('#tag-related-tags-error-<%= @tag.id.to_i %>').empty()
$('#tag-notions-error-<%= @tag.id.to_i %>').empty()
$('#tag-aliases-error-<%= @tag.id.to_i %>').empty()

# display error messages
<% if @errors.present? %>

<% if @errors[:courses].present? %>
$('#tag-courses-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:courses].join(" ") %>').show()
<% end %>

<% if @errors[:notions].present? %>
<% if @errors.messages[:"notions.title"].present? %>
$('#tag-notions-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:"notions.title"].first %>')
  .show()
<% else%>
$('#tag-notions-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:notions].join(" ") %>').show()
<% end %>
<% end %>

<% if @errors[:aliases].present? %>
<% if @errors.messages[:"aliases.title"].present? %>
$('#tag-aliases-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:"aliases.title"].first %>')
  .show()
<% else %>
$('#tag-aliases-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:aliases].join(" ") %>').show()
<% end %>
<% end %>

<% if @errors[:related_tags].present? %>
$('#tag-related-tags-error-<%= @tag.id.to_i %>')
  .append('<%= @errors[:related_tags].join(" ") %>').show()
<% end %>

<% else %>
# no errors present

<% if @modal %>
$('#newTagModal').modal('hide')
# update tag selectors depending on where the new tag modal was called from
if $('#newTagModal').data('from') == 'section'
  tagSelector = document.getElementById('section_tag_ids_<%= @section&.id&.to_i %>').selectize
  tagSelector.addOption({ value: <%= @tag.id %>, text: '<%= @tag.title %>'})
  tagSelector.refreshOptions(false)
  tagSelector.addItem(<%= @tag.id %>)
  tagSelector.refreshItems()
else if $('#newTagModal').data('from') == 'medium'
  tagSelector = document.getElementById('medium_tag_ids').selectize
  tagSelector.addOption({ value: <%= @tag.id %>, text: '<%= @tag.title %>'})
  tagSelector.refreshOptions(false)
  tagSelector.addItem(<%= @tag.id %>)
  tagSelector.refreshItems()
else if $('#newTagModal').data('from') == 'lesson'
  tagSelector = document.getElementById('lesson_tag_ids').selectize
  tagSelector.addOption({ value: <%= @tag.id %>, text: '<%= @tag.title %>'})
  tagSelector.refreshOptions(false)
  tagSelector.addItem(<%= @tag.id %>)
  tagSelector.refreshItems()
else if $('#newTagModal').data('from') == 'tag'
  tagSelector = document.getElementById('tag_related_tag_ids').selectize
  tagSelector.addOption({ value: <%= @tag.id %>, text: '<%= @tag.title %>'})
  tagSelector.refreshOptions(false)
  tagSelector.addItem(<%= @tag.id %>)
  tagSelector.refreshItems()
else
  location.reload(true)
<% end %>
<% end %>
