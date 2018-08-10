$(document).on 'turbolinks:load', ->
  news = document.getElementById('twitter-news')
  if news?
    profile = news.dataset.profile
    if profile?
      if news.dataset.twitter?
        location.reload()
      else
        $.getScript "https://platform.twitter.com/widgets.js", ->
          twttr.widgets.createTimeline({
            sourceType: 'profile',
            screenName: profile
          }, news, height: 200, chrome: 'noheader nofooter')
          news.dataset.twitter = true
  return
