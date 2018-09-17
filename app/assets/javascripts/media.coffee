# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

secondsToTime = (seconds) ->
  date = new Date(null)
  date.setSeconds seconds
  return date.toISOString().substr(12, 7)

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

  $('[id^="search_all_"]').on 'change', ->
    selector = document.getElementById(this.dataset.id).selectize
    if $(this).prop('checked')
      selector.disable()
    else
      selector.enable()
    return

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

  $('#medium-basics-cancel').on 'click', ->
    location.reload()
    return

  $('#detach-video').on 'click', ->
     $('#upload-video-hidden').val('')
     $('#video-meta').hide()
     $('#video-preview-area').hide()
     $('#medium_detach_video').val('true')
     $('#medium-basics-warning').show()
     return

  $('#detach-manuscript').on 'click', ->
    $('#upload-manuscript-hidden').val('')
    $('#manuscript-meta').hide()
    $('#manuscript-preview').hide()
    $('#medium_detach_manuscript').val('true')
    $('#medium-basics-warning').show()
    return

  $(document).on 'click', '#test-external-link', ->
    url = $('#medium_external_reference_link').val()
    window.open(url, '_blank')
    return

  $(document).on 'change', '#item_sort', ->
    $('#item_section_select').show()
    $('#item_number_field').show()
    if $(this).val() == 'section'
      $('#item_section_id').trigger('change')
      $("label[for='item_description']").empty().append('Titel')
    else
      $('#item_section_select').show()
      $('#item_number_field').hide() if $(this).val() == 'label'
      $('#item_description_field').show()
      $("label[for='item_description']").empty().append('Beschreibung')
    return

  $(document).on 'change', '#item_section_id', ->
    if $(this).val() != '' && $('#item_sort').val() == 'section'
      $('#item_description').val('')
      $('#item_description_field').hide()
      $('#item_number_field').hide()
    else
      $('#item_description_field').show()
      $('#item_number_field').show() unless $('#item_sort').val() == 'label'
    return

  $(document).on 'click', '[id^="tocitem-"]', ->
    time = this.dataset.time
    item = this.dataset.item
    video = document.getElementById('video-edit')
    video.pause()
    video.currentTime = time
    $.ajax Routes.edit_item_path(item),
      type: 'GET'
      dataType: 'script'
    return

  $(document).on 'click', '#cancel-item', ->
    $('#action-placeholder').empty()
    $('#action-container').empty()
    return

  $(document).on 'click', '[id^="metaref-"]', ->
    time = this.dataset.time
    referral = this.dataset.referral
    video = document.getElementById('video-edit')
    video.pause()
    video.currentTime = time
    $.ajax Routes.edit_referral_path(referral),
      type: 'GET'
      dataType: 'script'
    return

  $(document).on 'change', '#referral_item_id', ->
    itemId = $(this).val()
    refId = $('#referral_ref_id').val()
    if itemId == ''
      $('#link_reappearance').hide()
      $('#item_details').hide()
      $('#link_details').show()
      $('#referral_link').val('')
      $('#referral_description').val('')
      $('#referral_explanation').val('')
    else
      $.ajax Routes.display_item_path(itemId),
        type: 'GET'
        dataType: 'script'
        data: {
          referral_id: refId
        }
    return

  $(document).on 'click', '#test-link', ->
    url = $('#referral_link').val()
    window.open(url, '_blank')
    return

  $(document).on 'click', '.timer', ->
    video = document.getElementById('video-edit')
    video.pause()
    time = video.currentTime
    intTime = Math.floor(time)
    roundTime = intTime + Math.floor((time - intTime) * 1000) / 1000
    video.currentTime = roundTime
    $('#' + this.dataset.timer).val(fancyTimeFormat(video.currentTime))
    return

  $('#export-toc').on 'click', (e) ->
    e.preventDefault()
    $.fileDownload $(this).prop('href'),
      successCallback: (url) ->
        return
      failCallback: (url) ->
        console.log 'Download failed'
        return
    return

  $('#export-screenshot').on 'click', (e) ->
    e.preventDefault()
    $.fileDownload $(this).prop('href'),
      successCallback: (url) ->
        return
      failCallback: (url) ->
        console.log 'Download failed'
        return
    return

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
  $(document).off 'click', '[id^="tocitem-"]'
  $(document).off 'click', '[id^="metaref-"]'
  $(document).off 'change', '#referral_item_id'
  return
