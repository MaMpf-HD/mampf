$('.readerItem').remove()
$('.mediaCommentsDecoration').remove()
$('#mediaCommentsSize').empty().append('(0)').data('size', 0)
<% unless @anything_left %>
$('#commentsIcon').removeClass('new-comment')
<% end %>
$('#noCommentsAlert').show()