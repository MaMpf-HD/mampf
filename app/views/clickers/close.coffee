$('#openClickerButton').show()
$('#closeClickerButton').hide()
$('.clickerOpen').hide()
clearInterval(window.getClickerVotes)
$('.clickerVotesCount').empty().append('<%= @clicker.votes.count %>')
$('#votesGfx').empty()
<% if @clicker.results.present? %>
$('#votesGfx')
  .append('<%= j render partial: "clickers/edit/results",
                        locals: { clicker: @clicker } %>')
<% end %>
$('.clickerClosed').show()
$('.clickerAlternatives').prop('disabled', false)
$('.associateClickerQuestion').show()
$('#removeClickerQuestion').show()
