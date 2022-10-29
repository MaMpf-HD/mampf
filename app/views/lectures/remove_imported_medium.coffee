<% if @lecture.imported_media.size.positive? %>
$('.imported-medium-row[data-medium="<%= @medium&.id %>"]').remove()
<% else %>
$('#importedMediaTable').empty()
  .append($('#importedMediaTable').data('nomedia'))
<% end %>
$('#importedMediaCount').empty()
  .append('<%= "(#{@lecture.imported_media.size})" %>')