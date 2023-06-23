# a boolean that helps to deactivate all key listeners
# for the time the annotation modal opens and the user
# has to write text into the command box
lockKeyListeners = false

# when callig the updateMarkers() method this will be used to save an
# array containing all annotations
annotations = null

# helps to find the annotation that is currently shown in the
# annotation area
activeAnnotationId = 0

# if the window width (in px) gets below this threshold value, hide the control bar
# (default value)
hideControlBarThreshold =
  x: 850
  y: 500

# convert time in seconds to string of the form H:MM:SS
secondsToTime = (seconds) ->
  date = new Date(null)
  date.setSeconds seconds
  return date.toISOString().substr(12, 7)

# converts a json timestamp to a double containing the absolute count of millitseconds
timestampToMillis = (timestamp) ->
  return 3600 * timestamp.hours + 60 * timestamp.minutes + timestamp.seconds + 0.001 * timestamp.milliseconds

# converts a given integer between 0 and 255 into a hexadecimal, s.t. e.g. "15" becomes "0f"
# (instead of just "f") -> needed for correct format
toHexaDecimal = (int) ->
  if int > 15
    return int.toString(16)
  else
    return "0" + int.toString(16)

# lightens up a given color (given in a string in hexadecimal
# representation "#xxyyzz") such that e.g. black becomes dark grey.
# The higher the value of "factor" the brighter the colors become.
lightenUp = (color, factor) ->
  red   = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(5, 2))) / factor)
  green = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(3, 2))) / factor)
  blue  = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(1, 2))) / factor)
  return "#" + toHexaDecimal(blue) + toHexaDecimal(green) + toHexaDecimal(red)

sortAnnotations = ->
  if annotations == null
    return
  annotations.sort (ann1, ann2) ->
    timestampToMillis(ann1.timestamp) - timestampToMillis(ann2.timestamp)
  return

# return the start time of the next chapter relative to a given time in seconds
nextChapterStart = (seconds) ->
  chapters = document.getElementById('chapters')
  times = JSON.parse(chapters.dataset.times)
  return if times.length == 0
  i = 0
  while i < times.length
    return times[i] if times[i] > seconds
    ++i
  return

# return the start time of the previous chapter relative to a givben time in
# seconds
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

# hide control bar after 3 seconds of inactivity
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

# material icons that represent different media types
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

# returns the jQuery object of all metadata elements that start after the
# given time in seconds
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

# returns the jQuery object of all metadata elements that start before the
# given time in seconds
metadataBefore = (seconds) ->
  return $('[id^="m-"]').not(metadataAfter(seconds))

# for a given time, show all metadata elements that start before this time
# and hide all that start later
metaIntoView = (time) ->
  metadataAfter(time).hide()
  $before =  metadataBefore(time)
  $before.show()
  previousLength = $before.length
  if previousLength > 0
    $before.get(previousLength - 1).scrollIntoView()
  return

# set up everything: read out track data and initialize html elements
setupHypervideo = ->
  $chapterList = $('#chapters')
  $metaList = $('#metadata')
  video = $('#video').get 0
  backButton = document.getElementById('back-button')
  return if !video?
  document.body.style.backgroundColor = 'black'
  chaptersElement = $('#video track[kind="chapters"]').get 0
  metadataElement = $('#video track[kind="metadata"]').get 0

  # set up back button (transports back to the current chapter)
  displayBackButton = ->
    backButton.dataset.time = video.currentTime
    currentChapter = $('#chapters .current')
    if currentChapter.length > 0
      backInfo = currentChapter.data('text').split(':', 1)[0]
      if backInfo? && backInfo.length > 20
        backInfo = backButton.dataset.back
      else
        backInfo = backButton.dataset.backto + backInfo
      $(backButton).empty().append(backInfo).show()
      renderMathInElement backButton,
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

  # set up the chapter elements
  displayChapters = ->
    if chaptersElement.readyState == 2 and
    (chaptersTrack = chaptersElement.track)
      chaptersTrack.mode = 'hidden'
      i = 0
      times = []
      # read out the chapter track cues and generate html elements for chapters,
      # run katex on them
      while i < chaptersTrack.cues.length
        cue = chaptersTrack.cues[i]
        chapterName = cue.text
        start = cue.startTime
        times.push start
        $listItem = $("<li/>")
        $link = $("<a/>", { id: 'c-' + start, text: chapterName })
        $chapterList.append($listItem.append($link))
        chapterElement = $link.get(0)
        renderMathInElement chapterElement,
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
        $link.data('text', chapterName)
        # if a chapter element is clicked, transport to chapter start time
        $link.on 'click', ->
          displayBackButton()
          video.currentTime = @id.replace('c-', '')
          return
        ++i
      # store start times as data attribute
      $chapterList.get(0).dataset.times = JSON.stringify(times)
      $chapterList.show()
      # if the chapters cue changes (i.e. a switch between chapters), highlight
      # current chapter elment and scroll it into view, remove highlighting from
      # old chapter
      $(chaptersTrack).on 'cuechange', ->
        $('#chapters li a').removeClass 'current'
        if @activeCues.length > 0
          activeStart = @activeCues[0].startTime
          if chapter = document.getElementById('c-' + activeStart)
            $(chapter).addClass 'current'
            chapter.scrollIntoView()
        return
    return

  # set up the metadata elements
  displayMetadata = ->
    if metadataElement.readyState == 2 and (metaTrack = metadataElement.track)
      metaTrack.mode = 'hidden'
      i = 0
      times = []
      # read out the metadata track cues and generate html elements for
      # metadata, run katex on them
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
        $scriptIcon = $('<i/>',
          text: 'menu_book'
          class: 'material-icons')
        $scriptRef = $('<a/>',
          href: meta.script
          target: '_blank')
        $scriptRef.append($scriptIcon)
        $scriptRef.hide() unless meta.script?
        $quizIcon = $('<i/>',
          text: 'videogame_asset'
          class: 'material-icons')
        $quizRef = $('<a/>',
          href: meta.quiz
          target: '_blank')
        $quizRef.append($quizIcon)
        $quizRef.hide() unless meta.quiz?
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
        $icons.append($videoRef).append($manRef).append($scriptRef).append($quizRef).append($extRef)
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
        metaElement = $listItem.get(0)
        renderMathInElement metaElement,
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
        ++i
      # store metadata start times as data attribute
      $metaList.get(0).dataset.times = JSON.stringify(times)
      # if user jumps to a new position in the video, display all metadata
      # that start before this time and hide all that start later
      $(video).on 'seeked', ->
        time = video.currentTime
        metaIntoView(time)
        return
      # if the metadata cue changes, highlight all current media and scroll
      # them into view
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

  # after video metadata have been loaded, display chapters and metadata in the
  # interactive area
  # Originally (and more appropriately, according to the standards),
  # only the 'loadedmetadata' event was used. However, Firefox triggers this event to soon,
  # i.e. when the readyStates for chapters and elements are 1 (loading) instead of 2 (loaded)
  # for the events, see https://www.w3schools.com/jsref/event_oncanplay.asp
  initialChapters = true
  initialMetadata = true
  video.addEventListener 'loadedmetadata', ->
    if initialChapters and chaptersElement.readyState == 2
      displayChapters()
      initialChapters = false
    if initialMetadata and metadataElement.readyState == 2
      displayMetadata()
      initialMetadata = false

  video.addEventListener 'canplay', ->
    if initialChapters and chaptersElement.readyState == 2
      displayChapters()
      initialChapters = false
    if initialMetadata and metadataElement.readyState == 2
      displayMetadata()
      initialMetadata = false
  return

$(document).on 'turbolinks:load', ->
  thymeContainer = document.getElementById('thyme-container')
  # no need for thyme if no thyme container on the page
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
  emergencyButton = document.getElementById('emergency-button')
  annotationsToggle = document.getElementById('annotations-toggle-check')
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

  # User is teacher/editor for the given medium?
  #-> show toggle annotations button
  mediumId = thyme.dataset.medium
  $.ajax Routes.check_annotation_visibility_path(mediumId),
    type: 'GET'
    dataType: 'json'
    success: (isPermitted) ->
      if isPermitted
        $('#volume-controls').css('left', '66%')
        $('#speed-control').css('left', '77%')
        $('#emergency-button').css('left', '86%')
        hideControlBarThreshold.x = 960
        updateControlBarType()
      return

  # resizes the thyme container to the window dimensions, taking into account
  # whether the interactive area is displayed or hidden
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
    #iaHeight = $('#annotation-caption').css('height')
    #commentHeight = Number(iaHeight.substr(0, iaHeight.length - 2)) - 110
    #$('#annotation-comment').css('height', commentHeight + 'px')
    updateMarkers()
    return

  # detect IE/edge and inform user that they are not suppported if necessary,
  # only use browser player
  if document.documentMode || /Edge/.test(navigator.userAgent)
    alert($('body').data('badbrowser'))
    $('#caption').hide()
    $('#annotation-caption').hide()
    $('#video-controlBar').hide()
    video.style.width = '100%'
    video.controls = true
    document.body.style.backgroundColor = 'black'
    resizeContainer()
    window.onresize = resizeContainer
    return

  setupHypervideo()

  # on small mobile display, fall back to standard browser player
  mobileDisplay = ->
    $('#caption').hide()
    $('#annotation-caption').hide()
    $('#video-controlBar').hide()
    video.controls = true
    video.style.width = '100%'
    return

  # on large display, use anything thyme has to offer, disable native player
  largeDisplay = ->
    video.controls = false
    $('#caption').show()
    $('#annotation-caption').show()
    $('#video-controlBar').show()
    video.style.width = '82%'
    if iaButton.dataset.status == 'false'
      iaButton.innerHTML = 'remove_from_queue'
      $('#caption').hide()
      $('#annotation-caption').hide()
      video.style.width = '100%'
      $('#video-controlBar').css('width', '100%')
      $(window).trigger('resize')
    return

  updateControlBarType = ->
    # display native control bar if screen is very small
    if window.matchMedia("screen and (max-width: " + hideControlBarThreshold.x + "px)").matches or
       window.matchMedia("screen and (max-height: " + hideControlBarThreshold.y + "px)").matches
      mobileDisplay()

    if window.matchMedia("screen and (max-device-width: " + hideControlBarThreshold.x + "px)").matches or
       window.matchMedia("screen and (max-device-height: " + hideControlBarThreshold.y + "px)").matches
      mobileDisplay()

    # mediaQuery listener for very small screens
    match_verysmall_x = window.matchMedia("screen and (max-width: " + hideControlBarThreshold.x + "px)")
    match_verysmall_x.addListener (result) ->
      if result.matches
        mobileDisplay()
      return
    match_verysmall_y = window.matchMedia("screen and (max-height: " + hideControlBarThreshold.y + "px)")
    match_verysmall_y.addListener (result) ->
      if result.matches
        mobileDisplay()
      return

    match_verysmalldevice_x = window.matchMedia("screen and (max-device-width: " + hideControlBarThreshold.x + "px)")
    match_verysmalldevice_x.addListener (result) ->
      if result.matches
        mobileDisplay()
      return
    match_verysmalldevice_y = window.matchMedia("screen and (max-device-height: " + hideControlBarThreshold.y + "px)")
    match_verysmalldevice_y.addListener (result) ->
      if result.matches
        mobileDisplay()
      return

    # mediaQuery listener for normal screens
    match_normal_x = window.matchMedia("screen and (min-width: " + (hideControlBarThreshold.x + 1) + "px)")
    match_normal_x.addListener (result) ->
      match_normal_y = window.matchMedia("screen and (min-height: " + (hideControlBarThreshold.y + 1) + "px)")
      if result.matches && match_normal_y.matches
        largeDisplay()
      return
    match_normal_y = window.matchMedia("screen and (min-height: " + (hideControlBarThreshold.y + 1) + "px)")
    match_normal_y.addListener (result) ->
      match_normal_x = window.matchMedia("screen and (min-width: " + (hideControlBarThreshold.x + 1) + "px)")
      if result.matches && match_normal_x.matches
        largeDisplay()
      return

    match_normaldevice_x = window.matchMedia("screen and (min-device-width: " + (hideControlBarThreshold.x + 1) + "px)")
    match_normaldevice_x.addListener (result) ->
      match_normaldevice_y = window.matchMedia("screen and (min-device-height: " + (hideControlBarThreshold.y + 1) + "px)")
      if result.matches && match_normal_y.matches
        largeDisplay()
      return
    match_normaldevice_y = window.matchMedia("screen and (min-device-height: " + (hideControlBarThreshold.y + 1) + "px)")
    match_normaldevice_y.addListener (result) ->
      match_normaldevice_x = window.matchMedia("screen and (min-device-width: " + (hideControlBarThreshold.x + 1) + "px)")
      if result.matches && match_normal_x.matches
        largeDisplay()
      return
    return

  updateControlBarType()

  window.onresize = resizeContainer
  video.onloadedmetadata =  resizeContainer

  idleHideControlBar()

  # if mouse is moved or screen is toiched, show control bar
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

  # Event handler for the emergency button
  emergencyButton.addEventListener 'click', ->
    video.pause()
    $.ajax Routes.new_annotation_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        total_seconds: video.currentTime
        mediumId: thyme.dataset.medium
      }
    # When the modal opens, all key listeners must be
    # deactivated until the modal gets closed again
    lockKeyListeners = true
    $('#annotation-modal').on('hidden.bs.modal', ->
      lockKeyListeners = false
    )
    return

  if annotationsToggle != null
    annotationsToggle.addEventListener 'click', ->
      updateMarkers()

  # Update annotations after submitting the annotations form
  $(document).on 'click', '#submit-button', ->
    # NOTE:
    # Updating might take some time on the backend,
    # so I added a slight delay.
    # I couldn't think of an easy way to let the script
    # wait for the update to complete (as with the delete button),
    # but it might be possible!
    setTimeout(updateMarkers, 500)

  # Update annotations after deleting an annotation
  $(document).on 'click', '#delete-button', ->
    annotationId = Number(document.getElementById('annotation_id').textContent)
    $.ajax Routes.annotation_path(annotationId),
      type: 'DELETE'
      dataType: 'json'
      data: {
        annotationId: annotationId
      }
      success: ->
        updateMarkers()
        $('#annotation-close-button').click()
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

  # Event handler for interactive area activation button
  iaButton.addEventListener 'click', ->
    if iaButton.dataset.status == 'true'
      iaButton.innerHTML = 'remove_from_queue'
      iaButton.dataset.status = 'false'
      $('#caption').hide()
      $('#annotation-caption').hide()
      video.style.width = '100%'
      $('#video-controlBar').css('width', '100%')
      $(window).trigger('resize')
    else
      iaButton.innerHTML = 'add_to_queue'
      iaButton.dataset.status = 'true'
      video.style.width = '82%'
      $('#video-controlBar').css('width', '82%')
      $('#caption').show()
      $('#annotation-caption').show()
      $(window).trigger('resize')
    return

  # Event Handler for Back Button
  backButton.addEventListener 'click', ->
    video.currentTime = this.dataset.time
    $(backButton).hide()
    $('#back-reference').hide()
    return

  # Event handler for close interactive area button
  iaClose.addEventListener 'click', ->
    $(iaButton).trigger('click')
    return

  # Event listener for the full-screen button
  # unfortunately, lots of brwoser specific code
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
    if document.fullscreenElement != null
      fullScreenButton.innerHTML = 'fullscreen_exit'
      fullScreenButton.dataset.status = 'true'
    else
      fullScreenButton.innerHTML = 'fullscreen'
      fullScreenButton.dataset.status = 'false'
      # brute force patch: apparently, after exiting fullscreen mode,
      # window.onresize is triggered twice(!), the second time with incorrect
      # window height data, which results in a video area not quite filling
      # the whole window. The next line resizes the container again.
      setTimeout(resizeContainer, 20)
    return

  document.onwebkitfullscreenchange = ->
    if document.webkitFullscreenElement != null
      fullScreenButton.innerHTML = 'fullscreen_exit'
      fullScreenButton.dataset.status = 'true'
    else
      fullScreenButton.innerHTML = 'fullscreen'
      fullScreenButton.dataset.status = 'false'
      setTimeout(resizeContainer, 20)
    return

  document.onmozfullscreenchange = ->
    if document.mozFullScreenElement != null
      fullScreenButton.innerHTML = 'fullscreen_exit'
      fullScreenButton.dataset.status = 'true'
    else
      fullScreenButton.innerHTML = 'fullscreen'
      fullScreenButton.dataset.status = 'false'
      setTimeout(resizeContainer, 20)
    return

  # Event listeners for the seek bar
  seekBar.addEventListener 'input', ->
    time = video.duration * seekBar.value / 100
    video.currentTime = time
    return

  # if mouse is moved over seek bar, display tooltip with current chapter
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

  # if videomedtadata have been loaded, set up video length, volume bar and
  # seek bar
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
  # uses a gradient for seekbar video time visualization
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
  volumeBar.addEventListener 'input', ->
    value = volumeBar.value
    video.volume = value
    return

  video.addEventListener 'volumechange', ->
    value = video.volume
    volumeBar.value = value
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' +
    ' #2497E3, #2497E3 ' + value*100 + '%, #ffffff ' + value*100 + '%, #ffffff)'
    return

  video.addEventListener 'click', ->
    if video.paused == true
      video.play()
    else
      video.pause()
    showControlBar()
    return

  # thyme can be used by keyboard as well
  # Arrow up - next chapter
  # Arrow down - previous chapter
  # Arrow right - plus ten seconds
  # Arrow left - minus ten seconds
  # f - fullscreen
  # Page up - volume up
  # Page down - volume down
  # m - mute
  # i - toggle interactive area
  window.addEventListener 'keydown', (evt) ->
    if lockKeyListeners == true
      return
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

  # updates the annotation markers
  updateMarkers = ->
    mediumId = thyme.dataset.medium
    toggled = $('#annotations-toggle-check').is(":checked")
    $.ajax Routes.update_markers_path(),
      type: 'GET'
      dataType: 'json'
      data: {
        mediumId: mediumId
        toggled: toggled
      }
      success: (annots) ->
        annotations = annots
        sortAnnotations()
        $('#markers').empty()
        if annotations == null
          return
        flag = false
        for annotation in annotations
          createMarker(annotation)
          if annotation.id == activeAnnotationId
            updateAnnotationArea(annotation)
            flag = true
        if flag == false && $('#annotation-caption').is(":visible") == true
          $('#annotation-caption').hide()
          $('#caption').show()
        return
    return

  # an auxiliary method for "updateMarkers()" creating a single marker
  createMarker = (annotation) ->
    # create marker
    markerStr = '<span id="marker-' + annotation.id + '">
                  <svg width="15" height="15">
                  <polygon points="1,1 9,1 5,10"
                  style="fill:' + annotation.color + ';
                  stroke:black;stroke-width:1;fill-rule:evenodd;"/>
                 </svg></span>'
    $('#markers').append(markerStr)
    # set the correct position for the marker
    marker = $('#marker-' + annotation.id)
    size = seekBar.clientWidth - 15
    ratio = timestampToMillis(annotation.timestamp) / video.duration
    offset = marker.parent().offset().left + ratio * size + 3
    marker.offset({ left: offset })
    marker.on 'click', ->
      updateAnnotationArea(annotation)
      $('#caption').hide()
      $('#annotation-caption').show()
    return

  updateAnnotationArea = (annotation) ->
    activeAnnotationId = annotation.id
    comment = annotation.comment.replaceAll('\n', '<br>')
    headColor = lightenUp(annotation.color, 2)
    backgroundColor = lightenUp(annotation.color, 3)
    if annotation.subtext != null
      add = " (" + annotation.subtext + ")"
    else
      add = ""
    $('#annotation-infobar').empty().append(annotation.category + add)
    $('#annotation-infobar').css('background-color', headColor)
    $('#annotation-infobar').css('text-align', 'center')
    $('#annotation-comment').empty().append(comment)
    $('#annotation-caption').css('background-color', backgroundColor)
    # remove old listeners
    $('#annotation-previous-button').off 'click'
    $('#annotation-next-button').off 'click'
    $('#annotation-goto-button').off 'click'
    $('#annotation-edit-button').off 'click'
    $('#annotation-close-button').off 'click'
    # previous annotation listener
    $('#annotation-previous-button').on 'click', ->
      for i in [0 .. annotations.length - 1]
        if i != 0 && annotations[i] == annotation
          updateAnnotationArea(annotations[i - 1])
    # next annotation Listener
    $('#annotation-next-button').on 'click', ->
      for i in [0 .. annotations.length - 1]
        if i != annotations.length - 1 && annotations[i] == annotation
          updateAnnotationArea(annotations[i + 1])
    # goto listener
    $('#annotation-goto-button').on 'click', ->
      video.currentTime = timestampToMillis(annotation.timestamp)
    # edit listener
    $('#annotation-edit-button').on 'click', ->
      lockKeyListeners = true
      $.ajax Routes.edit_annotation_path(annotation.id),
      type: 'GET'
      dataType: 'script'
      data: {
        annotationId: annotation.id
      }
      success: (permitted) ->
        if permitted == "false"
          alert "You don't have the permission to edit this annotation!"
      return
    # close listener
    $('#annotation-close-button').on 'click', ->
      activeAnnotationId = 0
      $('#annotation-caption').hide()
      $('#caption').show()
    # LaTex
    renderMathInElement document.getElementById('annotation-comment'),
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
