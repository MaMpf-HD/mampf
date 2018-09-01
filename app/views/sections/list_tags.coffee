$('#section-tag-list-<%= @id %>').empty()
  .append('<%= j render partial: "tags/list",
                          locals: { tags: @tags, inspection: true } %>')
