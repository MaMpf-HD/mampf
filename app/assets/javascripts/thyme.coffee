primaryTarget = (meta) ->
  return meta.manuscript if meta.manuscript?
  return meta.video if meta.video?
  meta.link

secondsToTime = (seconds) ->
  date = new Date(null)
  date.setSeconds seconds
  return date.toISOString().substr(12, 7)

nextChapterStart = (seconds) ->
  chapters = document.getElementById('chapters')
  times = JSON.parse(chapters.dataset.times)
  return if times.length == 0
  i = 0
  while i < times.length
    return times[i] if times[i] > seconds
    ++i
  return

previousChapterStart = (seconds) ->
  chapters = document.getElementById('chapters')
  times = JSON.parse(chapters.dataset.times)
  return if times.length == 0
  i = times.length - 1
  while i > -1
    if times[i] < seconds
      return times[i] if seconds - times[i] > 3
      return times[i-1] if i > 0
    --i
  return

showControlBar = ->
  $('#video-controlBar').css('visibility', 'visible')
  $('#video').css('cursor', '')
  return

hideControlBar = ->
  $('#video-controlBar').css('visibility', 'hidden')
  $('#video').css('cursor', 'none')
  return

idleHideControlBar = ->
  t = undefined

  resetTimer = ->
    clearTimeout t
    t = setTimeout hideControlBar, 3000
    return

  window.onload = resetTimer
  window.onmousemove = resetTimer
  window.onmousedown = resetTimer
  window.ontouchstart = resetTimer
  window.onclick = resetTimer
  return

iconClass = (type) ->
  if type == 'video'
    return 'video_library'
  else if type == 'text'
    return 'library_books'
  else if type == 'quiz'
    return 'games'
  else if type == 'info'
    return 'info'
  return

metadataAfter = (seconds) ->
  metaList = document.getElementById('metadata')
  times = JSON.parse(metaList.dataset.times)
  return $() if times.length == 0
  i = 0
  while i < times.length
    if times[i] > seconds
      $nextMeta = $('#m-' + $.escapeSelector(times[i]))
      return $nextMeta.add($nextMeta.nextAll())
    ++i
  return $()

metadataBefore = (seconds) ->
  return $('[id^="m-"]').not(metadataAfter(seconds))

metaIntoView = (time) ->
  metadataAfter(time).hide()
  $before =  metadataBefore(time)
  $before.show()
  previousLength = $before.length
  if previousLength > 0
    $before.get(previousLength - 1).scrollIntoView()
  return

setupHypervideo = ->
  $chapterList = $('#chapters')
  $metaList = $('#metadata')
  video = $('#video').get 0
  backButton = document.getElementById('back-button')
  return if !video?
  document.body.style.backgroundColor = 'black'
  chaptersElement = $('#video track[kind="chapters"]').get 0
  metadataElement = $('#video track[kind="metadata"]').get 0

  displayBackButton = ->
    backButton.dataset.time = video.currentTime
    currentChapter = $('#chapters .current')
    if currentChapter.length > 0
      backInfo = currentChapter.data('text').split(':', 1)[0]
      if backInfo? && backInfo.length > 20
        backInfo = 'zurück'
      else
        backInfo = 'zurück zu ' + backInfo
      $(backButton).empty().append(backInfo).show()
      MathJax.Hub.Queue [
        'Typeset'
        MathJax.Hub
        backButton.id
      ]
    return

  displayChapters = ->
    if chaptersElement.readyState == 2 and
    (chaptersTrack = chaptersElement.track)
      chaptersTrack.mode = 'hidden'
      i = 0
      times = []
      while i < chaptersTrack.cues.length
        cue = chaptersTrack.cues[i]
        chapterName = cue.text
        start = cue.startTime
        times.push start
        $listItem = $("<li/>")
        $link = $("<a/>", { id: 'c-' + start, text: chapterName })
        $chapterList.append($listItem.append($link))
        if MathJax?
          MathJax.Hub.Queue [
            'Typeset'
            MathJax.Hub
            'c-' + start
          ]
        else
          console.log 'MathJax ist noch nicht da.'
        $('#c-' + $.escapeSelector(start)).data('text', chapterName)
        $('#c-' + $.escapeSelector(start)).on 'click', ->
          displayBackButton()
          video.currentTime = @id.replace('c-', '')
          return
        ++i
      $chapterList.get(0).dataset.times = JSON.stringify(times)
      $chapterList.show()
      $(chaptersTrack).on 'cuechange', ->
        $('#chapters li a').removeClass 'current'
        if @activeCues.length > 0
          activeStart = @activeCues[0].startTime
          if chapter = document.getElementById('c-' + activeStart)
            $(chapter).addClass 'current'
            chapter.scrollIntoView()
        return
    return

  displayMetadata = ->
    if metadataElement.readyState == 2 and (metaTrack = metadataElement.track)
      metaTrack.mode = 'hidden'
      i = 0
      times = []
      while i < metaTrack.cues.length
        cue = metaTrack.cues[i]
        meta = JSON.parse cue.text
        start = cue.startTime
        times.push start
        $listItem = $('<li/>', id: 'm-' + start)
        $listItem.hide()
        $link = $('<a/>',
          text: meta.reference
          class: 'item'
          id: 'l-' + start)
        $videoIcon = $('<i/>',
          text: 'video_library'
          class: 'material-icons')
        $videoRef = $('<a/>',
          href: meta.video
          target: '_blank')
        $videoRef.append($videoIcon)
        $videoRef.hide() unless meta.video?
        $manIcon = $('<i/>',
          text: 'library_books'
          class: 'material-icons')
        $manRef = $('<a/>',
          href: meta.manuscript
          target: '_blank')
        $manRef.append($manIcon)
        $manRef.hide() unless meta.manuscript?
        $extIcon = $('<i/>',
          text: 'link'
          class: 'material-icons')
        $extRef = $('<a/>',
          href: meta.link
          target: '_blank')
        $extRef.append($extIcon)
        $extRef.hide() unless meta.link?
        $description = $('<div/>',
          text: meta.text
          class: 'mx-3')
        $explanation = $('<div/>',
          text: meta.explanation
          class: 'm-3')
        $details = $('<div/>')
        $details.append($link).append($description).append($explanation)
        $icons = $('<div/>',
          style: 'flex-shrink: 3; display: flex; flex-direction: column;')
        $icons.append($videoRef).append($manRef).append($extRef)
        $listItem.append($details).append($icons)
        $metaList.append($listItem)
        $videoRef.on 'click', ->
          video.pause()
          return
        $manRef.on 'click', ->
          video.pause()
          return
        $extRef.on 'click', ->
          video.pause()
          return
        $link.on 'click', ->
          displayBackButton()
          video.currentTime = this.id.replace('l-','')
          return
        if MathJax?
          MathJax.Hub.Queue [
            'Typeset'
            MathJax.Hub
            'm-' + start
          ]
        else
          console.log 'MathJax ist noch nicht da.'
        ++i
      $metaList.get(0).dataset.times = JSON.stringify(times)
      $(video).on 'seeked', ->
        time = video.currentTime
        metaIntoView(time)
        return
      $(metaTrack).on 'cuechange', ->
        j = 0
        time = video.currentTime
        $('#metadata li').removeClass 'current'
        while j<@activeCues.length
          activeStart = @activeCues[j].startTime
          if metalink = document.getElementById('m-' + activeStart)
            $(metalink).show()
            $(metalink).addClass 'current'
          ++j
        currentLength =  $('#metadata .current').length
        if currentLength > 0
          $('#metadata .current').get(length - 1).scrollIntoView()
        return
    return

  $(video).on 'loadedmetadata', ->
    if chaptersElement.readyState == 2
      displayChapters()
      displayMetadata()
    else
      alert('Es ist ein Fehler beim Laden der Metadaten aufgetreten.')
  return

$(document).on 'turbolinks:load', ->
  thymeContainer = document.getElementById('thyme-container')
  return if thymeContainer == null
  # Video
  video = document.getElementById('video')
  thyme = document.getElementById('thyme')
  # Buttons
  playButton = document.getElementById('play-pause')
  muteButton = document.getElementById('mute')
  iaButton = document.getElementById('ia-active')
  iaClose = document.getElementById('ia-close')
  fullScreenButton = document.getElementById('full-screen')
  plusTenButton = document.getElementById('plus-ten')
  minusTenButton = document.getElementById('minus-ten')
  nextChapterButton = document.getElementById('next-chapter')
  previousChapterButton = document.getElementById('previous-chapter')
  backButton = document.getElementById('back-button')
  # Sliders
  seekBar = document.getElementById('seek-bar')
  volumeBar = document.getElementById('volume-bar')
  # Selectors
  speedSelector = document.getElementById('speed')
  # Time
  currentTime = document.getElementById('current-time')
  maxTime = document.getElementById('max-time')
  # ControlBar
  videoControlBar = document.getElementById('video-controlBar')

  # function that resizes the thyme container
  resizeContainer = ->
    height = $(window).height()
    factor = if $('#caption').is(':hidden') then 1 else 1 / 0.82
    width = Math.floor((video.videoWidth * $(window).height() /
    video.videoHeight) * factor)
    if width > $(window).width()
      shrink = $(window).width() / width
      height = Math.floor(height * shrink)
      width = $(window).width()
    top = Math.floor(0.5*($(window).height() - height))
    left = Math.floor(0.5*($(window).width() - width))
    $('#thyme-container').css('height', height + 'px')
    $('#thyme-container').css('width', width + 'px')
    $('#thyme-container').css('top', top + 'px')
    $('#thyme-container').css('left', left + 'px')
    return

  # detect IE/edge and cancel if true
  if document.documentMode || /Edge/.test(navigator.userAgent)
    alert 'Dein Browser wird von Thyme leider nicht unterstützt.' +
    'Du kannst das Video nur mit dem Browser-Player aunschauen.'
    $('#caption').hide()
    $('#video-controlBar').hide()
    video.style.width = '100%'
    video.controls = true
    document.body.style.backgroundColor = 'black'
    resizeContainer()
    window.onresize = resizeContainer
    return

  setupHypervideo()

  # iOS no fullscreen button
  iOS = ! !navigator.platform and /iPad|iPhone/.test(navigator.platform)
  fullScreenButton.style.display = 'none' if iOS

  mobileDisplay = ->
    $('#caption').hide()
    $('#video-controlBar').hide()
    video.controls = true
    video.style.width = '100%'
    return

  largeDisplay = ->
    video.controls = false
    $('#caption').show()
    $('#video-controlBar').show()
    video.style.width = '82%'
    return

  # display native control bar if screen is very small
  if window.matchMedia("screen and (max-width: 767px)").matches
    mobileDisplay()

  if window.matchMedia("screen and (max-device-width: 767px)").matches
    mobileDisplay()

  # mediaQuery listener for very small screens
  match_verysmall = window.matchMedia("screen and (max-width: 767px)")
  match_verysmall.addListener (result) ->
    if result.matches
      mobileDisplay()
    return

  match_verysmalldevice = window.matchMedia("screen and (max-device-width: 767px)")
  match_verysmalldevice.addListener (result) ->
    if result.matches
      mobileDisplay()
    return

  # mediaQuery listener for normal screens
  match_normal = window.matchMedia("screen and (min-width: 768px)")
  match_normal.addListener (result) ->
    if result.matches
      largeDisplay()
    return

  match_normal = window.matchMedia("screen and (min-device-width: 768px)")
  match_normal.addListener (result) ->
    if result.matches
      largeDisplay()
    return

  window.onresize = resizeContainer
  video.onloadedmetadata =  resizeContainer

  idleHideControlBar()
  video.addEventListener 'mouseover', showControlBar, false
  video.addEventListener 'mousemove', showControlBar, false
  video.addEventListener 'touchstart', showControlBar, false

  # Event listener for the play/pause button
  playButton.addEventListener 'click', ->
    if video.paused == true
      video.play()
    else
      video.pause()
    return

  video.onplay = ->
    playButton.innerHTML = 'pause'

  video.onpause = ->
    playButton.innerHTML = 'play_arrow'

  # Event listener for the mute button
  muteButton.addEventListener 'click', ->
    if video.muted == false
      video.muted = true
      muteButton.innerHTML = 'volume_off'
    else
      video.muted = false
      muteButton.innerHTML = 'volume_up'
    return

  # Event handler for the plusTen button
  plusTenButton.addEventListener 'click', ->
    video.currentTime = Math.min(video.currentTime + 10, video.duration)
    return

  # Event handler for the minusTen button
  minusTenButton.addEventListener 'click', ->
    video.currentTime = Math.max(video.currentTime - 10, 0)
    return

  # Event handler for the nextChapter button
  nextChapterButton.addEventListener 'click', ->
    next = nextChapterStart(video.currentTime)
    video.currentTime = nextChapterStart(video.currentTime) if next?
    return

  # Event handler for the previousChapter button
  previousChapterButton.addEventListener 'click', ->
    previous = previousChapterStart(video.currentTime)
    video.currentTime = previousChapterStart(video.currentTime) if previous?
    return

  # Event handler for speed speed selector
  speedSelector.addEventListener 'change', ->
    if video.preservesPitch?
      video.preservesPitch = true
    else if video.mozPreservesPitch?
      video.mozPreservesPitch = true
    else if video.webkitPreservesPitch?
      video.webkitPreservesPitch = true
    video.playbackRate = @options[@selectedIndex].value
    return

  # Event handler for ia activation button
  iaButton.addEventListener 'click', ->
    if iaButton.dataset.status == 'true'
      iaButton.innerHTML = 'remove_from_queue'
      iaButton.dataset.status = 'false'
      $('#caption').hide()
      video.style.width = '100%'
      $('#video-controlBar').css('width', '100%')
      $(window).trigger('resize')
    else
      iaButton.innerHTML = 'add_to_queue'
      iaButton.dataset.status = 'true'
      video.style.width = '82%'
      $('#video-controlBar').css('width', '82%')
      $('#caption').show()
      $(window).trigger('resize')
    return

  # Event Handler for Back Button
  backButton.addEventListener 'click', ->
    video.currentTime = this.dataset.time
    $(backButton).hide()
    $('#back-reference').hide()
    return

  # Event handler for close ia button
  iaClose.addEventListener 'click', ->
    $(iaButton).trigger('click')
    return

  # Event listener for the full-screen button
  fullScreenButton.addEventListener 'click', ->
    if fullScreenButton.dataset.status == 'true'
      if document.exitFullscreen
        document.exitFullscreen()
      else if document.mozCancelFullScreen
        document.mozCancelFullScreen()
      else if document.webkitExitFullscreen
        document.webkitExitFullscreen()
    else
      if thymeContainer.requestFullscreen
        thymeContainer.requestFullscreen()
      else if thymeContainer.mozRequestFullScreen
        thymeContainer.mozRequestFullScreen()
      else if thymeContainer.webkitRequestFullscreen
        thymeContainer.webkitRequestFullscreen()
    return

  document.onfullscreenchange = ->
    if document.FullscreenElement != null
      fullScreenButton.innerHTML = 'fullscreen_exit'
      fullScreenButton.dataset.status = 'true'
    else
      fullScreenButton.innerHTML = 'fullscreen'
      fullScreenButton.dataset.status = 'false'
    return

  document.onwebkitfullscreenchange = ->
    if document.webkitFullscreenElement != null
      fullScreenButton.innerHTML = 'fullscreen_exit'
      fullScreenButton.dataset.status = 'true'
    else
      fullScreenButton.innerHTML = 'fullscreen'
      fullScreenButton.dataset.status = 'false'
    return

  document.onmozfullscreenchange = ->
    if document.mozFullScreenElement != null
      fullScreenButton.innerHTML = 'fullscreen_exit'
      fullScreenButton.dataset.status = 'true'
    else
      fullScreenButton.innerHTML = 'fullscreen'
      fullScreenButton.dataset.status = 'false'
    return

  # Event listener for the seek bar
  seekBar.addEventListener 'input', ->
    time = video.duration * seekBar.value / 100
    video.currentTime = time
    return

  seekBar.addEventListener 'mousemove', (evt) ->
    positionInfo = seekBar.getBoundingClientRect()
    width = positionInfo.width;
    left = positionInfo.left
    measuredSeconds = ((evt.pageX - left)/width) * video.duration
    seconds = Math.min(measuredSeconds, video.duration)
    seconds = Math.max(seconds, 0)
    previous = previousChapterStart(seconds)
    info = $('#c-' + $.escapeSelector(previous)).text().split(':')[0]
    seekBar.setAttribute('title', info)
    return

  video.addEventListener 'loadedmetadata', ->
    maxTime.innerHTML = secondsToTime(video.duration)
    volumeBar.value = video.volume
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' +
      ' #2497E3, #2497E3 ' + video.volume*100 + '%, #ffffff ' +
      video.volume*100 + '%, #ffffff)'
    if video.dataset.time?
      time = video.dataset.time
      video.currentTime = time
      seekBar.value = video.currentTime / video.duration * 100
    else
      seekBar.value = 0
    return

  # Update the seek bar as the video plays
  video.addEventListener 'timeupdate', ->
    value = 100 / video.duration * video.currentTime
    seekBar.value = value
    seekBar.style.backgroundImage = 'linear-gradient(to right,' +
    ' #2497E3, #2497E3 ' + value + '%, #ffffff ' + value + '%, #ffffff)'
    currentTime.innerHTML = secondsToTime(video.currentTime)
    return

  # Pause the video when the seek handle is being dragged
  seekBar.addEventListener 'mousedown', ->
    video.dataset.paused = video.paused
    video.pause()
    return

  # Play the video when the seek handle is dropped
  seekBar.addEventListener 'mouseup', ->
    video.play() unless video.dataset.paused == 'true'
    return

  # Event listener for the volume bar
  volumeBar.addEventListener 'change', ->
    value = volumeBar.value
    video.volume = value
    return

  video.addEventListener 'volumechange', ->
    value = video.volume
    volumeBar.value = value
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' +
    ' #2497E3, #2497E3 ' + value*100 + '%, #ffffff ' + value*100 + '%, #ffffff)'
    return

  window.addEventListener 'keydown', (evt) ->
    key = evt.key
    if key == ' '
      if video.paused == true
        video.play()
      else
        video.pause()
    else if key == 'ArrowUp'
      $(nextChapterButton).trigger('click')
    else if key == 'ArrowDown'
      $(previousChapterButton).trigger('click')
    else if key == 'ArrowRight'
      $(plusTenButton).trigger('click')
    else if key == 'ArrowLeft'
      $(minusTenButton).trigger('click')
    else if key == 'f'
      $(fullScreenButton).trigger('click')
    else if key == 'PageUp'
      video.volume = Math.min(video.volume + 0.1, 1)
    else if key == 'PageDown'
      video.volume = Math.max(video.volume - 0.1, 0)
    else if key == 'm'
      $(muteButton).trigger('click')
    else if key == 'i'
      $(iaButton).trigger('click')
    return
  return
