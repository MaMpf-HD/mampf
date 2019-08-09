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


webNotificationPoll = ->
  channel = $('#clickerChannel')
  url = channel.data('url')
  val = $('input[name="vote[value]"]:checked').val();
  $.ajax(
    url: url
    ifModified: true
    dataType: 'html'
    ).done (response, statusText, xhr) ->
    console.log xhr.status
    console.log val
    if response?
      $('#clickerChannel').html($(response).find('#clickerChannel').html())
      $('#vote_value_' + val).prop('checked',true);
    return
  return


window.onload = ->
  channel = $('#clickerChannel')
  if channel.length > 0
    window.clickerChannelId = setInterval(webNotificationPoll, 4000)
  return
