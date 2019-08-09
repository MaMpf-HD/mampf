<% if @errors == 'voted already' %>
clearInterval(window.clickerChannelId)
$('body').empty().append('Du hast schon abgestimmt')
<% else %>
clearInterval(window.clickerChannelId)
$('body').empty().append('Danke für Dein Votum!')
<% end %>