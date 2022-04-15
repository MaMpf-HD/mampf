<% if current_user.admin || @medium.edited_with_inheritance_by?(current_user) %>
tagSelector = document.getElementById('medium_tag_ids')
tagSelectize = tagSelector.selectize
tagSelectize.clear()
<% @tag_ids.each do |t| %>
tagSelectize.addItem(<%= t %>)
<% end %>
<% end %>
$('#edit_tag_form').show()
$('#mediumActions').hide()
$('#medium_id_field').val(<%= @medium.id %>)