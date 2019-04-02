<% if @success %>
$('#remark-basics-warning').addClass 'no_display'
$('#remark-basics-options').addClass 'no_display'
<% else %>
alert 'Fehler beim Abspeichern der Bemerkung'
<% end %>
