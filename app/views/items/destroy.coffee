# rerender the toc box and the references box
$('#toc-area').empty()
  .append('<%= j render partial: 'media/toc',
                        locals: { medium: @medium } %>')
$('#meta-area').empty()
  .append('<%= j render partial: "media/reference",
                        locals: { medium: @medium } %>')

# hide export toc buttons if there are  no toc items
<% if @medium.items.blank? %>
$('#export-toc').hide()
<% end %>

# clean up action box
$('#action-placeholder').empty()
$('#action-container').empty()
