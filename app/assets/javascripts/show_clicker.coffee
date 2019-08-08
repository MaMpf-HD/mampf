# Plain js Poll
# Problem: html caching does not work
# (even when server sends a 304, everything is refreshed)
# webNotificationPoll = ->
#   xhr = new XMLHttpRequest
#   channel = document.getElementById('clickerChannel')
#   url = channel.dataset.url
#   xhr.open 'GET', url + '?layout=0'
#   xhr.onload = ->
#     console.log xhr.getResponseHeader("Last-Modified")
#     if xhr.status == 200
#       channel.innerHTML = xhr.responseText
#     return
#   xhr.send()
#   return


webNotificationPoll = ->
  channel = $('#clickerChannel')
  url = channel.data('url') + '?layout=0'
  $.ajax(
    url: url
    ifModified: true
    ).done (response) ->
    if response?
      $('body').empty().append(response)
    return
  return


window.onload = ->
  setInterval(webNotificationPoll, 4000)
  return
