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
    $('#publish-medium-button').hide()
    teachableSelector = document.getElementById('medium_teachable').selectize
    value = teachableSelector.getValue()
    if value != ''
      $('#medium_teachable_id').val(value.split('-')[1])
      $('#medium_teachable_type').val(value.split('-')[0])
    else
      $('#medium_teachable_id').val('')
      $('#medium_teachable_type').val('')
    return

  $('#medium_sort').on 'change', ->
    if $(this).val() == 'Script'
      $('#mampfStyInfo').show()
    else
      $('#mampfStyInfo').hide()
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

  $('#publish-medium-button').on 'click', ->
    $('#publishMediumModal').modal('show')
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

  $('#import-from-manuscript').on 'click', ->
    mediumId = $(this).data('mediumid')
    okay = confirm('Bist Du sicher?')
    return unless okay
    count = $(this).data('count') - 1
    filter_boxes = []
    for c in [0..count]
      tag_checked = $('#tag-' + c).prop('checked')
      shown_checked = $('#visible-' + c).prop('checked')
      filter_boxes.push [c, tag_checked, shown_checked]
    $.ajax Routes.import_manuscript_path(mediumId),
      type: 'POST'
      dataType: 'script'
      data: {
        id: mediumId
        filter_boxes: JSON.stringify(filter_boxes)
      }
    return

  $(document).on 'mouseenter', '[id^="row-medium-"]', ->
    if $(this).data('purpose') in ['media', 'clicker']
      mediumActions = document.getElementById('mediumActions')
      unless mediumActions.dataset.filled == 'true'
        $(this).addClass('bg-orange-lighten-4')
        $.ajax Routes.fill_medium_preview_path(),
          type: 'GET'
          dataType: 'script'
          data: {
            id: $(this).data('id')
            type: $(this).data('type')
          }
          error: (jqXHR, textStatus, errorThrown) ->
             console.log("AJAX Error: #{textStatus}")
    else if $(this).data('purpose') == 'quiz'
      $('#previewHeader').show()
      $(this).addClass('bg-orange-lighten-4')
      $.ajax Routes.fill_quizzable_preview_path(),
        type: 'GET'
        dataType: 'script'
        data: {
          id: $(this).data('id')
          type: $(this).data('type')
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    else if $(this).data('purpose') == 'import'
      $('#previewHeader').show()
      $(this).addClass('bg-orange-lighten-4')
      $.ajax Routes.fill_medium_preview_path(),
        type: 'GET'
        dataType: 'script'
        data: {
          id: $(this).data('id')
          type: $(this).data('type')
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'mouseleave', '[id^="row-medium-"]', ->
    $(this).removeClass('bg-orange-lighten-4')
    return

  $(document).on 'click', '[id^="row-medium-"]', ->
    if $(this).data('purpose') in ['media', 'clicker']
      mediumActions = document.getElementById('mediumActions')
      if $(this).hasClass('bg-green-lighten-4')
        $(this).removeClass('bg-green-lighten-4')
        $('#mediumPreview').empty()
        $('#mediumActions').empty()
        $('[id^="row-medium-"]').css('cursor', 'pointer')
        mediumActions.dataset.filled = 'false'
      else
        $('[id^="row-medium-"]').removeClass('bg-green-lighten-4')
        $(this).removeClass('bg-orange-lighten-4').addClass('bg-green-lighten-4')
        $('[id^="row-medium-"]').css('cursor','')
        if $(this).data('purpose') == 'media'
          $.ajax Routes.render_medium_actions_path(),
            type: 'GET'
            dataType: 'script'
            data: {
              id: $(this).data('id')
            }
            error: (jqXHR, textStatus, errorThrown) ->
              console.log("AJAX Error: #{textStatus}")
        else if $(this).data('purpose') == 'clicker'
          $.ajax Routes.render_clickerizable_actions_path(),
            type: 'GET'
            dataType: 'script'
            data: {
              id: $(this).data('id')
              clicker: $('#clickerSearchForm').data('clicker')
            }
            error: (jqXHR, textStatus, errorThrown) ->
              console.log("AJAX Error: #{textStatus}")
    else if $(this).data('purpose') == 'quiz'
      $(this).removeClass('bg-orange-lighten-4').addClass('bg-green-lighten-4')
      $.ajax Routes.render_import_vertex_path(),
        type: 'GET'
        dataType: 'script'
        data: {
          quiz_id: $('#new_vertex').data('quiz')
          id: $(this).data('id')
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    else if $(this).data('purpose') == 'import'
      $(this).removeClass('bg-orange-lighten-4').addClass('bg-green-lighten-4')
      $.ajax Routes.render_import_media_path(),
        type: 'GET'
        dataType: 'script'
        data: {
          id: $(this).data('id')
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#cancel-import-media', ->
    $('#mediumPreview').empty()
    $('[id^="row-medium-"]').removeClass('bg-green-lighten-4')
    importTab = document.getElementById('importMedia')
    importTab.dataset.selected = '[]'
    if $(this).data('purpose') == 'import'
      $.ajax Routes.cancel_import_media_path(),
        type: 'GET'
        dataType: 'script'
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    else if $(this).data('purpose') == 'quiz'
      $.ajax Routes.cancel_import_vertex_path(),
        type: 'GET'
        dataType: 'script'
        data: {
          quiz_id: $('#new_vertex').data('quiz')
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#submit-import-media', ->
    importTab = document.getElementById('importMedia')
    selected = JSON.parse(importTab.dataset.selected)
    if $(this).data('purpose') == 'import'
      lectureId = importTab.dataset.lecture
      $.ajax Routes.lecture_import_media_path(lectureId),
        type: 'POST'
        dataType: 'script'
        data: {
          media_ids: selected
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    else if $(this).data('purpose') == 'quiz'
      quizId = $('#new_vertex').data('quiz')
      $.ajax Routes.quiz_vertices_path(quiz_id: quizId),
        type: 'POST'
        dataType: 'script'
        data: {
          vertex: {
            sort: 'import'
            quizzable_ids: selected
          }
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#import-media-button', ->
    $(this).hide()
    $('#importedMediaArea').show()
    return

  $(document).on 'click', '#editMediumTags', ->
    $.ajax Routes.render_medium_tags_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: $(this).data('medium')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#cancelMediumTags', ->
    $('#edit_tag_form').hide()
    $('#mediumActions').show()
    return

  # restore page if creation of new lesson is cancelled
  $(document).on 'click', '#cancel-new-medium', ->
    console.log 'Hi'
    $('#new-medium-area').empty().hide()
    $('.fa-edit').show()
    $('.new-in-lecture').show()
    $('[data-toggle="collapse"]').removeClass('disabled')
    return

  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#test-external-link'
  $(document).off 'click', '.timer'
  $(document).off 'click', '#export-toc'
  $(document).off 'click', '#export-references'
  $(document).off 'click', '#export-screenshot'
  $(document).off 'mouseenter', '[id^="row-medium-"]'
  $(document).off 'mouseleave', '[id^="row-medium-"]'
  $(document).off 'click', '[id^="row-medium-"]'
  $(document).off 'click', '#cancel-import-media'
  $(document).off 'click', '#submit-import-media'
  $(document).off 'click', '#import-media-button'
  $(document).off 'click', '#cancel-medium-actions'
  $(document).off 'click', '#editMediumTags'
  $(document).off 'click', '#cancelMediumTags'
  $(document).off 'click', '#cancel-new-medium'
  return
