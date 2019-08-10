$('#clickerOpen').hide()
<% if @errors == 'voted already' %>
$('#votedAlready').show()
<% else %>
$('#thankVote').show()
<% end %>