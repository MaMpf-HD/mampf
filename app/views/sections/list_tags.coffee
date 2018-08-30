if $('#section-tag-list-<%= @id %>').data('show') == 0
  $('#section-tag-list-<%= @id %>')
    .append('<%= j render partial: "tags/list",
                          locals: { tags: @tags } %>')
  $('#section-tag-list-<%= @id %>').data('show', 1)
  $('#section-tag-links-<%= @id %>').text('Tag-Links ausblenden')
else
  $('#section-tag-list-<%= @id %>').empty()
  $('#section-tag-list-<%= @id %>').data('show', 0)
  $('#section-tag-links-<%= @id %>').text('Tag-Links einblenden')  
