$(document).on 'turbolinks:load', ->
  news = document.getElementById('twitter-news')
  console.log 'turbolinks: ja'
  if news?
    console.log 'news: ja'
    profile = news.dataset.profile
    if profile?
      console.log 'profil: ja'
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
