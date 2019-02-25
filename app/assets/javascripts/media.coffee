# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# converts a time in seconds given as a float to a string of the form
# hh:mm:ss.MMM
fancyTimeFormat = (time) ->
  floor_seconds = Math.floor(time)
  milli = Math.round((time - floor_seconds) * 1000)
  hrs = Math.floor(floor_seconds / 3600)
  mins = Math.floor(floor_seconds % 3600 / 60)
  secs = floor_seconds % 60
  output  = hrs + ':' + (if mins < 10 then '0' else '')
  output += '' + mins + ':' + (if secs < 10 then '0' else '')
  output += '' + secs + '.' + (if milli < 100 then '0' else '')
  output += '' + (if milli < 10 then '0' else '') + milli
  output

$(document).on 'turbolinks:load', ->

  # disable/enable search field on the media search page, depending on
  # whether 'all tags'/'all editors'/... are selected
  $('[id^="search_all_"]').on 'change', ->
    selector = document.getElementById(this.dataset.id).selectize
    if $(this).prop('checked')
      selector.disable()
    else
      selector.enable()
    return

  # issue a warning if an input has been changed in the media form
  # extract the teachable type and id from the teachable selection and
  # store it in hidden fields' values
  # (relevant on media edit page)
  $('#medium-form :input').on 'change', ->
    $('#medium-basics-warning').show()
    teachableSelector = document.getElementById('medium_teachable').selectize
    value = teachableSelector.getValue()
    if value != ''
      $('#medium_teachable_id').val(value.split('-')[1])
      $('#medium_teachable_type').val(value.split('-')[0])
    else
      $('#medium_teachable_id').val('')
      $('#medium_teachable_type').val('')
    return

  # reload page if editing of medium is cancelled
  # (relevant on media edit page)
  $('#medium-basics-cancel').on 'click', ->
    location.reload()
    return

  # reload page (thereby closing the modal) if user wants to keep
  # named destination items that point to no longer existing pdf destinations
  # (relevant on media edit page)
  $('#keep-old-destinations').on 'click', ->
    location.reload()
    return

  # trigger deletion of named destination that no longer point to existing
  # pdf destinations
  # (relevant on media edit page)
  $('#quarantine-old-destinations').on 'click', ->
    mediumId = $(this).data('mediumId')
    destinations = $(this).data('destinations')
    $.ajax Routes.quarantine_destinations_path(mediumId),
      type: 'GET'
      dataType: 'script'
      data: {
        id: mediumId
        destinations: destinations
      }
      success: ->
        location.reload()
        return
    return

  # if user detaches video, adjust hidden values
  # (relevant on media edit page)
  $('#detach-video').on 'click', ->
     $('#upload-video-hidden').val('')
     $('#video-meta').hide()
     $('#video-preview-area').hide()
     $('#medium_detach_video').val('true')
     $('#medium-basics-warning').show()
     return

  # if user detaches manuscript, adjust hidden values
  # (relevant on media edit page)
  $('#detach-manuscript').on 'click', ->
    $('#upload-manuscript-hidden').val('')
    $('#manuscript-meta').hide()
    $('#manuscript-preview').hide()
    $('#medium_detach_manuscript').val('true')
    $('#medium-basics-warning').show()
    return

  # test external link provided by the user in an external tab
  # (relevant on media edit page)
  $(document).on 'click', '#test-external-link', ->
    url = $('#medium_external_reference_link').val()
    window.open(url, '_blank')
    return

  # grab current time from video and put the value in the associated input field
  # (relevant on media enrich page)
  $(document).on 'click', '.timer', ->
    video = document.getElementById('video-edit')
    video.pause()
    time = video.currentTime
    intTime = Math.floor(time)
    roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000
    video.currentTime = roundTime
    $('#' + this.dataset.timer).val(fancyTimeFormat(video.currentTime))
    return

  # trigger file download for toc .vtt file
  # (relevant on media enrich page)
  $('#export-toc').on 'click', (e) ->
    e.preventDefault()
    $.fileDownload $(this).prop('href'),
      successCallback: (url) ->
        return
      failCallback: (url) ->
        console.log 'Download failed'
        return
    return

  # trigger file download for video screenshot .png file
  # (relevant on media enrich page)
  $('#export-screenshot').on 'click', (e) ->
    e.preventDefault()
    $.fileDownload $(this).prop('href'),
      successCallback: (url) ->
        return
      failCallback: (url) ->
        console.log 'Download failed'
        return
    return

  # trigger file download for references .vtt file
  # (relevant on media enrich page)
  $('#export-references').on 'click', (e) ->
    e.preventDefault()
    $.fileDownload $(this).prop('href'),
      successCallback: (url) ->
        return
      failCallback: (url) ->
        console.log 'Download failed'
        return
    return

  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#test-external-link'
  $(document).off 'click', '.timer'
  $(document).off 'click', '#export-toc'
  $(document).off 'click', '#export-references'
  $(document).off 'click', '#export-screenshot'
  return
