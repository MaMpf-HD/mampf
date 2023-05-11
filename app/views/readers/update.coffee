<% if @thread %>
$('.readerItem[data-thread="<%= @thread.id %>"]').fadeOut().remove()
$size = $('#mediaCommentsSize')
newSize = parseInt($size.data('size')) - 1
$size.empty().append('(' + newSize + ')').data('size', newSize)
$('.mediaCommentsDecoration').remove() if newSize == 0
<% unless @anything_left %>
$('#commentsIcon').removeClass('new-comment')
$('#noCommentsAlert').show()
<% end %>
<% end %>