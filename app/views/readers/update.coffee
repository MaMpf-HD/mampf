<% if @thread %>
$('.readerItem[data-thread="<%= @thread.id %>"]').fadeOut().remove()
$size = $('#mediaCommentsSize')
newSize = parseInt($size.data('size')) - 1
$size.empty().append('(' + newSize + ')').data('size', newSize)
$('.mediaCommentsDecoration').remove() if newSize == 0
<% end %>