<% if @success %>
$('#question-basics-warning').addClass 'no_display'
$('#question-basics-options').addClass 'no_display'
<% else %>
alert 'Fehler beim Abspeichern der Frage'
<% end %>
