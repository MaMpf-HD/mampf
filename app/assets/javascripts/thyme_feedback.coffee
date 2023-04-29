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

# convert time in seconds to string of the form H:MM:SS
secondsToTime = (seconds) ->
  date = new Date(null)
  date.setSeconds seconds
  return date.toISOString().substr(12, 7)

# converts a json timestamp to a double containing the absolute count of millitseconds
timestampToMillis = (timestamp) ->
  return 3600 * timestamp.hours + 60 * timestamp.minutes + timestamp.seconds + 0.001 * timestamp.milliseconds

# lightens up a given color (given in a string in hexadecimal
# representation "#xxyyzz") such that e.g. black becomes dark grey.
# The higher the value of "factor" the brighter the colors become.
lightenUp = (color, factor) ->
  red   = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(5, 2))) / factor)
  green = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(3, 2))) / factor)
  blue  = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(1, 2))) / factor)
  return "#" + blue.toString(16) + green.toString(16) + red.toString(16)

sortAnnotations = ->
  if annotations == null
    return
  annotations.sort (ann1, ann2) ->
    timestampToMillis(ann1.timestamp) - timestampToMillis(ann2.timestamp)
  return

# set up everything: read out track data and initialize html elements
setupHypervideo = ->
  video = $('#video').get 0
  return if !video?
  document.body.style.backgroundColor = 'black'

$(document).on 'turbolinks:load', ->
  thymeContainer = document.getElementById('thyme-feedback')
  # no need for thyme if no thyme container on the page
  return if thymeContainer == null
  # Video
  video = document.getElementById('video')
  thyme = document.getElementById('thyme')
  # Buttons
  playButton = document.getElementById('play-pause')
  muteButton = document.getElementById('mute')
  plusTenButton = document.getElementById('plus-ten')
  minusTenButton = document.getElementById('minus-ten')
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

  # resizes the thyme container to the window dimensions
  resizeContainer = ->
    height = $(window).height()
    width = Math.floor((video.videoWidth * $(window).height() / video.videoHeight))
    if width > $(window).width()
      shrink = $(window).width() / width
      height = Math.floor(height * shrink)
      width = $(window).width()
    top = Math.floor(0.5*($(window).height() - height))
    left = Math.floor(0.5*($(window).width() - width))
    $('#thyme-feedback').css('height', height + 'px')
    $('#thyme-feedback').css('width', width + 'px')
    $('#thyme-feedback').css('top', top + 'px')
    $('#thyme-feedback').css('left', left + 'px')
    updateMarkers()
    return

  setupHypervideo()
  resizeContainer()
  window.onresize = resizeContainer
  video.onloadedmetadata =  resizeContainer

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
  # Page up - volume up
  # Page down - volume down
  # m - mute
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
    else if key == 'PageUp'
      video.volume = Math.min(video.volume + 0.1, 1)
    else if key == 'PageDown'
      video.volume = Math.max(video.volume - 0.1, 0)
    else if key == 'm'
      $(muteButton).trigger('click')
    return

  # updates the annotation markers
  updateMarkers = ->
    mediumId = thyme.dataset.medium
    $.ajax Routes.update_markers_path(),
      type: 'GET'
      dataType: 'json'
      data: {
        mediumId: mediumId
      }
      success: (annots) ->
        annotations = annots
        sortAnnotations()
        $('#markers').empty()
        if annotations == null
          return
        for annotation in annotations
          createMarker(annotation)
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
      alert "todo"
    return
  return