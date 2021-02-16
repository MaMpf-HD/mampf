# convert time in seconds to string of the form H:MM:SS
secondsToTime = (seconds) ->
  date = new Date(null)
  date.setSeconds seconds
  return date.toISOString().substr(12, 7)

# convert given dataURL to Blob, used for converting screenshot canvas to png
dataURLtoBlob = (dataURL) ->
  # Decode the dataURL
  binary = atob(dataURL.split(',')[1])
  # Create 8-bit unsigned array
  array = []
  i = 0
  while i < binary.length
    array.push binary.charCodeAt(i)
    i++
  # Return our Blob object
  new Blob([ new Uint8Array(array) ], type: 'image/png')

$(document).on 'turbolinks:load', ->
  thymeEdit = document.getElementById('thyme-edit')
  return if thymeEdit == null
  mediumId = thymeEdit.dataset.medium
  # Video
  video = document.getElementById('video-edit')
  # Buttons
  playButton = document.getElementById('play-pause')
  muteButton = document.getElementById('mute')
  plusTenButton = document.getElementById('plus-ten')
  plusFiveButton = document.getElementById('plus-five')
  plusOneButton = document.getElementById('plus-one')
  minusOneButton = document.getElementById('minus-one')
  minusFiveButton = document.getElementById('minus-five')
  minusTenButton = document.getElementById('minus-ten')
  addItemButton = document.getElementById('add-item')
  addReferenceButton = document.getElementById('add-reference')
  addScreenshotButton = document.getElementById('add-screenshot')
  # Sliders
  seekBar = document.getElementById('seek-bar')
  volumeBar = document.getElementById('volume-bar')
  # Time
  currentTime = document.getElementById('current-time')
  maxTime = document.getElementById('max-time')
  # ControlBar
  videoControlBar = document.getElementById('video-controlBar-edit')
  # Screenshot Canvas
  canvas = document.getElementById('snapshot')

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

  # Event handler for the plusFive button
  plusFiveButton.addEventListener 'click', ->
    video.currentTime = Math.min(video.currentTime + 5, video.duration)
    return

  # Event handler for the plusOne button
  plusOneButton.addEventListener 'click', ->
    video.currentTime = Math.min(video.currentTime + 1, video.duration)
    return

  # Event handler for the minusOne button
  minusOneButton.addEventListener 'click', ->
    video.currentTime = Math.max(video.currentTime - 1, 0)
    return

  # Event handler for the minusFive button
  minusFiveButton.addEventListener 'click', ->
    video.currentTime = Math.max(video.currentTime - 5, 0)
    return

  # Event handler for the minusTen button
  minusTenButton.addEventListener 'click', ->
    video.currentTime = Math.max(video.currentTime - 10, 0)
    return

  # Event listener for the seek bar
  seekBar.addEventListener 'input', ->
    time = video.duration * seekBar.value / 100
    video.currentTime = time
    return

  # Event listener for addItem button
  addItemButton.addEventListener 'click', ->
    video.pause()
    # round time down to three decimal digits
    time = video.currentTime
    intTime = Math.floor(time)
    roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000
    video.currentTime = roundTime
    $.ajax Routes.add_item_path(mediumId),
      type: 'GET'
      dataType: 'script'
      data: {
        time: video.currentTime
      }
    return

  # Event listener for addItem button
  addReferenceButton.addEventListener 'click', ->
    video.pause()
    # round time down to three decimal digits
    time = video.currentTime
    intTime = Math.floor(time)
    roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000
    video.currentTime = roundTime
    $.ajax Routes.add_reference_path(mediumId),
      type: 'GET'
      dataType: 'script'
      data: {
        time: video.currentTime
      }
    return

  # Event listener for add screenshot button
  addScreenshotButton.addEventListener 'click', ->
    video.pause()
    # extract video screenshot from canvas
    context = canvas.getContext('2d')
    context.drawImage(video, 0, 0, canvas.width, canvas.height)
    base64image = canvas.toDataURL('image/png')
    # Get our file
    file = dataURLtoBlob(base64image)
    # Create new form data
    fd = new FormData
    # Append our Canvas image file to the form data
    fd.append 'image', file
    # And send it
    $.ajax Routes.add_screenshot_path(mediumId),
      type: 'POST'
      data: fd
      processData: false
      contentType: false
    return

  # after video metadata have been loaded, set up video length, volume bar and
  # seek bar
  video.addEventListener 'loadedmetadata', ->
    maxTime.innerHTML = secondsToTime(video.duration)
    volumeBar.value = video.volume
    volumeBar.style.backgroundImage = 'linear-gradient(to right,' +
      ' #2497E3, #2497E3 ' + video.volume*100 + '%, #ffffff ' +
      video.volume*100 + '%, #ffffff)'
    seekBar.value = 0
    canvas.width = Math.floor($(video).width())
    canvas.height = Math.floor($(video).height())
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

  return
