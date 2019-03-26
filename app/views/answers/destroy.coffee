<% if @success %>
$('#answer-card-<%= @id %>').remove()
<% else %>
alert 'Fehler beim Löschen der Antwort'
<% end %>
