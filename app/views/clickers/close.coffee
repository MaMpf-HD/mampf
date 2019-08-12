$('#openClickerButton').show()
$('#closeClickerButton').hide()
$('.clickerOpen').hide()
clearInterval(window.getClickerVotes)
$('.clickerVotesCount').empty().append('<%= @clicker.votes.count %>')
$('#votesGfx').empty()
  .append('<%= j render partial: "clickers/edit/results",
                        locals: { clicker: @clicker } %>')
$('.clickerClosed').show()