<% if @success %>
$('#remark-basics-warning').addClass 'no_display'
$('#remark-basics-options').addClass 'no_display'
$('#remark-image-preview').empty()
  .append '<%= j render partial: "remarks/image_preview",
                        locals: { remark: @remark } %>'
<% else %>
alert 'Fehler beim Abspeichern der Bemerkung'
<% end %>
