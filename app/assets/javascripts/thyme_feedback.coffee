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

# mixes all colors in the array "colors" (wrtie colors as hexadecimal, e.g. "#1fe67d").
colorMixer = (colors) ->
  n = colors.length
  red = 0
  green = 0
  blue = 0
  for i in [0 .. n - 1]
    red += Number("0x" + colors[i].substr(5, 2))
    green += Number("0x" + colors[i].substr(3, 2))
    blue += Number("0x" + colors[i].substr(1, 2))
  red = Math.max(0, Math.min(255, Math.round(red / n)))
  green = Math.max(0, Math.min(255, Math.round(green / n)))
  blue = Math.max(0, Math.min(255, Math.round(blue / n)))
  return "#" + toHexaDecimal(blue) + toHexaDecimal(green) + toHexaDecimal(red)

sortAnnotations = ->
  if annotations == null
    return
  annotations.sort (ann1, ann2) ->
    timestampToMillis(ann1.timestamp) - timestampToMillis(ann2.timestamp)
  return

annotationIndex = (annotation) ->
  for i in [0 .. annotations.length - 1]
    if annotations[i].id == annotation.id
      return i
  return

# returns a certain color for every annotation with respect to the annotations
# category (in the feedback view this gives more information than the original color).
annotationColor = (cat) ->
  switch cat
    when "note" then return "#44ee11" #green
    when "content" then return "#eeee00" #yellow
    when "mistake" then return "#ff0000" #red
    when "presentation" then return "#ff9933" #orange
  return

# returns a color for the heatmap with respect to the annotation types that are shown.
heatmapColor = (colors) ->
  return colorMixer(colors)

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
  # below-area
  toggleNoteAnnotations = document.getElementById('toggle-note-annotations-check')
  toggleContentAnnotations = document.getElementById('toggle-content-annotations-check')
  toggleMistakeAnnotations = document.getElementById('toggle-mistake-annotations-check')
  togglePresentationAnnotations = document.getElementById('toggle-presentation-annotations-check')

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

  # Toggles which annotations are shown
  toggleNoteAnnotations.addEventListener 'click', ->
    updateMarkers()
    return

  toggleContentAnnotations.addEventListener 'click', ->
    updateMarkers()
    return

  toggleMistakeAnnotations.addEventListener 'click', ->
    updateMarkers()
    return

  togglePresentationAnnotations.addEventListener 'click', ->
    updateMarkers()
    return

  # updates the annotation markers
  updateMarkers = ->
    mediumId = thyme.dataset.medium
    $.ajax Routes.update_markers_path(),
      type: 'GET'
      dataType: 'json'
      data: {
        toggled: true
        mediumId: mediumId
      }
      success: (annots) ->
        annotations = annots
        sortAnnotations()
        $('#feedback-markers').empty()
        if annotations == null
          return
        for a in annotations
          if validAnnotation(a) == true
            createMarker(a)
        heatmap()
    return

  # an auxiliary method for "updateMarkers()" creating a single marker
  createMarker = (annotation) ->
    # create marker
    if annotation.category == "mistake"
      polygonPoints = "1,1 9,1 5,14"
      strokeWidth = 1.5
      strokeColor = "darkred"
    else
      polygonPoints = "1,5 9,5 5,14"
      strokeWidth = 1
      strokeColor = "black"

    markerStr = '<span id="marker-' + annotation.id + '">
                  <svg width="15" height="20">
                  <polygon points="' + polygonPoints + '"
                  style="fill:' + annotationColor(annotation.category) + ';
                  stroke:' + strokeColor + ';stroke-width:' + strokeWidth + ';fill-rule:evenodd;"/>
                 </svg></span>'
    $('#feedback-markers').append(markerStr)
    # set the correct position for the marker
    marker = $('#marker-' + annotation.id)
    size = seekBar.clientWidth - 15
    ratio = timestampToMillis(annotation.timestamp) / video.duration
    offset = marker.parent().offset().left + ratio * size + 3
    marker.offset({ left: offset })
    marker.on 'click', ->
      updateAnnotationArea(annotation)
    return

  updateAnnotationArea = (annotation) ->
    activeAnnotationId = annotation.id
    comment = annotation.comment.replaceAll('\n', '<br>')
    headColor = lightenUp(annotationColor(annotation.category), 2)
    backgroundColor = lightenUp(annotationColor(annotation.category), 3)
    if annotation.subtext != null
      add = " (" + annotation.subtext + ")"
    else
      add = ""
    $('#annotation-infobar').empty().append(annotation.category)
    $('#annotation-infobar').css('background-color', headColor)
    $('#annotation-infobar').css('text-align', 'center')
    $('#annotation-comment').empty().append(comment)
    $('#annotation-caption').css('background-color', backgroundColor)
    # remove old listeners
    $('#annotation-previous-button').off 'click'
    $('#annotation-next-button').off 'click'
    $('#annotation-goto-button').off 'click'
    $('#annotation-close-button').off 'click'
    # previous annotation listener
    $('#annotation-previous-button').on 'click', ->
      j = annotationIndex(annotation)
      for i in [j - 1 .. 0]
        if validAnnotation(annotations[i])
          updateAnnotationArea(annotations[i])
          return
    # next annotation Listener
    $('#annotation-next-button').on 'click', ->
      j = annotationIndex(annotation)
      for i in [j + 1 .. annotations.length - 1]
        if validAnnotation(annotations[i])
          updateAnnotationArea(annotations[i])
          return
    # goto listener
    $('#annotation-goto-button').on 'click', ->
      video.currentTime = timestampToMillis(annotation.timestamp)
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

  # Depending on the toggle switches, which are activated, this method checks, if
  # an annotation should be displayed or not.
  validAnnotation = (annotation) ->
    switch annotation.category
      when "note" then return $('#toggle-note-annotations-check').is(":checked")
      when "content" then return $('#toggle-content-annotations-check').is(":checked")
      when "mistake" then return $('#toggle-mistake-annotations-check').is(":checked")
      when "presentation" then return $('#toggle-presentation-annotations-check').is(":checked")
    return

  heatmap = ->
    if annotations == null
      return
    $('#heatmap').empty()

    #
    # variable definitions
    #
    radius = 10 #total distance from a single peak's maximum to it's minimum
    width = seekBar.clientWidth + 2 * radius - 35 #width of the video timeline
    maxHeight = video.clientHeight / 4 #the peaks of the graph should not extend maxHeight
    # An array for each pixel on the timeline. The indices of this array should be thought
    # of the x-axis of the heatmap's graph, while its entries should be thought of its
    # values on the y-axis.
    pixels = new Array(width + 2 * radius + 1).fill(0)
    # amplitude should be calculated with respect to all annotations
    # (even those which are not shown). Otherwise the peaks increase
    # when turning off certain annotations because the graph has to be
    # normed. Therefore we need this additional "pixelsAll" array.
    pixelsAll = new Array(width + 2 * radius + 1).fill(0)
    # for any visible annotation, this array contains its color (needed for the calculation
    # of the heatmap color)
    colors = []

    #
    # data calculation
    #
    for a in annotations
      valid = validAnnotation(a) && a.category != "mistake" # <- don't include mistake annotations
      if valid == true
        colors.push(annotationColor(a.category))
      time = timestampToMillis(a.timestamp)
      position = Math.round(width * (time / video.duration))
      for x in [position - radius .. position + radius]
        y = sinX(x, position, radius)
        pixelsAll[x + radius] += y
        if valid == true
          pixels[x + radius] += y
    maxValue = Math.max.apply(Math, pixelsAll)
    amplitude = maxHeight * (1 / maxValue)

    #
    # draw heatmap
    #
    pointsStr = "0," + maxHeight + " "
    for x in [0 .. pixels.length - 1]
      pointsStr += x + "," + (maxHeight - amplitude * pixels[x]) + " "
    pointsStr += "" + width + "," + maxHeight
    heatmapStr = '<svg width=' + (width + 35) + ' height="' + maxHeight + '">
                  <polyline points="' + pointsStr +
                  '" style="fill:' + heatmapColor(colors) +
                  '; fill-opacity:0.4; stroke:black; stroke-width:1"/></svg>'
    $('#heatmap').append(heatmapStr)
    offset = $('#heatmap').parent().offset().left - radius + 79
    $('#heatmap').offset({ left: offset })
    $('#heatmap').css('top', -maxHeight - 4) # vertical offset
    return

  # A modified sine function for building nice peaks around the marker positions.
  #
  # x = insert value
  # position = the position of the maximum value
  # radius = the distance from a minimum to a maximum of the sine wave
  sinX = (x, position, radius) ->
    return (1 + Math.sin(Math.PI / radius * (x - position) + Math.PI / 2)) / 2

  return