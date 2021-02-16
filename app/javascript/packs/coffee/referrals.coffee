# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # if a reference item is clicked in the references box, jump to the
  # corresponding time in the video and render edit referral view in the
  # action box
  # (relevant on media enrich page)
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

  # depending on whether an item is selected in the referral action box or not,
  # trigger rendering of the item's properties or hide the corresponding fields
  # (relevant on media enrich page)
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

  # react to a preselection of a teachable in the referral action box
  # by rendering all of this teachable's items as options in the item dropdown
  # (relevant on media enrich page)
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
          itemSelectize.addOption(result)
        itemSelectize.refreshOptions(false)
        $('#create_external_link').show() if teachableId == 'external-0'
        return
    return

  # test external link for reference in an external tab
  # (relevant on media enrich page)
  $(document).on 'click', '#test-link', ->
    url = $('#referral_link').val()
    window.open(url, '_blank')
    return

  return

# clean up for turbolinks
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#referral_item_id'
  $(document).off 'change', '#referral_teachable'
  $(document).off 'click', '#test-link'
  $(document).off 'click', '[id^="metaref-"]'
  return