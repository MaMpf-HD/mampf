# Plain js Poll
# Problem: html caching does not work
# (even when server sends a 304, everything is refreshed)
# webNotificationPoll = ->
#   xhr = new XMLHttpRequest
#   channel = document.getElementById('clickerChannel')
#   url = channel.dataset.url
#   xhr.open 'GET', url
#   xhr.onload = ->
#     console.log xhr.getResponseHeader("Last-Modified")
#     if xhr.status == 200
#       channel.innerHTML = xhr.responseText
#     return
#   xhr.send()
#   return

adjustVoteStatus = (channel) ->
  if channel.data('open')
    clickerId = channel.data('clicker')
    clickerInstance = channel.data('instance')
    clickerStatus = getCookie('clicker-' + clickerId)
    if clickerStatus == clickerInstance
      $('#clickerOpen').hide()
      $('#votedAlready').show()
  return

webNotificationPoll = ->
  channel = $('#clickerChannel')
  url = channel.data('url')
  $.ajax(
    url: url
    ifModified: true
    dataType: 'html'
    ).done (response, statusText, xhr) ->
    if response?
      responseChannel = $(response).find('#clickerChannel')
      clickerId = channel.data('clicker')
      clickerStatus = Cookies.get('clicker-' + clickerId)
      newClickerInstance = responseChannel.data('instance')
      newClickerOpen = responseChannel.data('open')
      $('#clickerChannel').html($(response).find('#clickerChannel').html())
      $('#clickerChannel').data('instance', newClickerInstance)
      $('#clickerChannel').data('open', newClickerOpen)
      if clickerStatus == newClickerInstance
        $('#clickerOpen').hide()
        $('#votedAlready').show()
      renderMathInElement document.getElementById('clickerChannel'),
        delimiters: [
          {
            left: '$$'
            right: '$$'
            display: true
          }
          {
            left: '$'
            right: '$'
            display: false
          }
          {
            left: '\\('
            right: '\\)'
            display: false
          }
          {
            left: '\\['
            right: '\\]'
            display: true
          }
        ]
        throwOnError: false
    return
  return


window.onload = ->
  channel = $('#clickerChannel')
  if channel.length > 0
    adjustVoteStatus(channel)
    channel.data('interval', -1)
    if document.visibilityState == 'visible'
      i =  setInterval(webNotificationPoll, 5000)
      channel.data('interval', i)
    renderMathInElement document.getElementById('clickerChannel'),
      delimiters: [
        {
          left: '$$'
          right: '$$'
          display: true
        }
        {
          left: '$'
          right: '$'
          display: false
        }
        {
          left: '\\('
          right: '\\)'
          display: false
        }
        {
          left: '\\['
          right: '\\]'
          display: true
        }
      ]
      throwOnError: false

    document.addEventListener 'visibilitychange', ->
      if document.visibilityState == 'visible'
        webNotificationPoll()
        console.log 'Visible again!'
        console.log 'Current interval:' + channel.data('interval')
        if channel.data('interval') == -1
          console.log 'Interval is empty'
          i = setInterval(webNotificationPoll, 5000)
          channel.data('interval', i)
          console.log 'New interval:' + channel.data('interval')
      else
        console.log 'Shutting down'
        console.log channel.data('interval')
        clearInterval(channel.data('interval'))
        channel.data('interval', -1)
      return

    $(document).on 'click', '.voteClicker', ->
      value = $(this).data('value')
      $('.voteClicker').remove()
      $('.votedClicker[data-value="'+value+'"]').addClass('active')
      $('.votedClicker').show()
      $.ajax $(this).data('url'),
        type: 'POST'
        dataType: 'script'
      return
  return
