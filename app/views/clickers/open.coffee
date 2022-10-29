getClickerVotes = ->
  $.ajax Routes.get_votes_count_path(<%= @clicker.id %>),
    type: 'GET'
    dataType: 'json'
    success: (result) ->
      $('.clickerVotesCount').empty().append(result)
      return
  return

$('.clickerVotesCount').empty().append('0')
$('#openClickerButton').hide()
$('#closeClickerButton').show()
$('.clickerClosed').hide()
$('.clickerOpen').show()
$('.clickerAlternatives').prop('disabled', true)
$('.associateClickerQuestion').hide()
$('#removeClickerQuestion').hide()
window.getClickerVotes = setInterval(getClickerVotes, 4000)