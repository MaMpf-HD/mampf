<% unless @errors.present? %>
$('.voteClicker').remove()
$('.votedClicker[data-value="<%= @vote.value %>"]').addClass('active')
$('.votedClicker').show()
<% end %>