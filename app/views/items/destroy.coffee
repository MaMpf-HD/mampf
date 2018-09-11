$('#toc-area').empty()
  .append('<%= j render partial: 'media/toc',
                        locals: { medium: @medium } %>')
$('#meta-area').empty()
  .append('<%= j render partial: "media/reference",
                        locals: { medium: @medium } %>')
<% if @medium.items.blank? %>
$('#export-toc').hide()
<% end %>
$('#action-placeholder').empty()
$('#action-container').empty()
