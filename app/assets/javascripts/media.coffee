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

  # issue a wrning if an inpu has been changed in the media form
  # extract the teachable type and id from the teachable selection and
  # store it in hidden fields' values
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

  $('#keep-old-destinations').on 'click', ->
    location.reload()
    return

  $('#delete-old-destinations').on 'click', ->
    mediumId = $(this).data('mediumId')
    destinations = $(this).data('destinations')
    $.ajax Routes.delete_destinations_path(mediumId),
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

  $(document).on 'change', '#item_pdf_destination', ->
    if $(this).val() != ''
      $('#item_page_field').hide()
    else
      $('#item_page_field').show()
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
      $('#item_details').hide()
      $('#link_details').hide()
      $('#explanation_details').hide()
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

  $(document).on 'change', '#referral_teachable', ->
    teachableId = $(this).val()
    $('#create_external_link').hide()
    if teachableId == ''
      itemSelectize = document.getElementById('referral_item_id').selectize
      itemSelectize.clear()
      itemSelectize.clearOptions()
      itemSelectize.refreshOptions(false)
      itemSelectize.refreshItems()
      return
    $.ajax Routes.list_items_path(),
      type: 'GET'
      dataType: 'json'
      data: {
        teachable_id: teachableId
      }
      success: (result) ->
        itemSelectize = document.getElementById('referral_item_id').selectize
        itemSelectize.clear()
        itemSelectize.clearOptions()
        if result?
          for r in result
            itemSelectize.addOption({ value: r[1], text: r[0] })
        itemSelectize.refreshOptions(false)
        $('#create_external_link').show() if teachableId == 'external-0'
        return
    return

  $(document).on 'click', '#test-link', ->
    url = $('#referral_link').val()
    window.open(url, '_blank')
    return

  $(document).on 'click', '#item-test-link', ->
    url = $('#item_link').val()
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

  $(document).on 'click', '#create_external_link', ->
    $('#external_item_form')[0].reset();
    $('#item_link').removeClass('is-invalid')
    $('#item-link-error').empty()
    $('#item_description').removeClass('is-invalid')
    $('#item-description-error').empty()
    $('#newItemModal').modal('show')
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
  $(document).off 'change', '#referral_teachable'
  return
