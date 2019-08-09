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
  url = channel.data('url')
  val = $('input[name="vote[value]"]:checked').val();
  $.ajax(
    url: url
    ifModified: true
    ).done (response) ->
    if response?
      $('#clickerChannel').html($(response).find('#clickerChannel').html())
    return
  return


window.onload = ->
  channel = $('#clickerChannel')
  if channel.length > 0
    window.clickerChannelId = setInterval(webNotificationPoll, 4000)
  return
