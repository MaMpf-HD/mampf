<% if @errors == 'voted already' %>
$('#votedAlready').show()
<% else %>
$('.voteClicker').remove()
$('.votedClicker[data-value="<%= @vote.value %>"]').addClass('active')
$('.votedClicker').show()
<% end %>