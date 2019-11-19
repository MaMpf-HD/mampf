# clean up from previous errors
$('#lesson-date-error').empty()
$('#lesson-sections-error').empty()


# display error messages
<% if @errors.any? %>
<% if @errors[:date].present? %>
$('#lesson-date-error')
  .append('<%= @errors[:date].join(" ") %>').show()
<% end %>
<% if @errors[:sections].present? %>
$('#lesson-sections-error')
  .append('<%= @errors[:sections].join(" ") %>').show()
<% end %>
<% else %>
<% if @tags_without_section.any? %>
$('#manage-tags-modal-content').empty()
  .append('<%= j render partial: "lessons/tags_associations",
                        locals:
                          { tags_without_section: @tags_without_section,
                            lesson: @lesson } %>')
$('#manageTagsModal').modal('show')
<% else %>
location.reload()
<% end %>
<% end %>