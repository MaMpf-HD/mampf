$('#edit_tag_form').hide()
$('#mediumActions').show()
$('.mediumTags[data-medium="<%= @medium.id %>"]')
  .empty().append('<%= j render partial: "tags/short_list",
                                locals: { tags: @medium.tags } %>')