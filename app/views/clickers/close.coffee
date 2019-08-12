$('#openClickerButton').show()
$('#closeClickerButton').hide()
$('.clickerOpen').hide()
clearInterval(window.getClickerVotes)
$('.clickerVotesCount').empty().append('<%= @clicker.votes.count %>')
<% if @clicker.results.present? %>
$('#votesGfx').empty()
  .append('<%= j render partial: "clickers/edit/results",
                        locals: { clicker: @clicker } %>')
<% end %>
$('.clickerClosed').show()