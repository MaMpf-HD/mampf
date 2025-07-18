# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # adjust which fields are shown depending on which item sort is selected
  # in the toc item edit view
  # (relevant on media enrich page)
  $(document).on 'change', '#item_sort', ->
    $('#item_section_select').show()
    $('#item_number_field').show()
    if $(this).val() == 'section'
      $('#item_section_id').trigger('change')
      $("label[for='item_description']").empty().append('Titel')
    else if $(this).val() == 'chapter'
      $('#item_section_select').hide()
      $("label[for='item_description']").empty().append('Titel')
    else
      $('#item_section_select').show()
      $('#item_number_field').hide() if $(this).val() == 'label'
      $('#item_description_field').show()
      $("label[for='item_description']").empty().append('Beschreibung')
    return

  # depending on whether an item belongs to a lecture's section or not,
  # hide or display the section description field in the toc item edit view
  # (relevant on media enrich page)
  $(document).on 'change', '#item_section_id', ->
    if $(this).val() != '' && $('#item_sort').val() == 'section'
      $('#item_description').val('')
      $('#item_description_field').hide()
      $('#item_number_field').hide()
    else
      $('#item_description_field').show()
      $('#item_number_field').show() unless $('#item_sort').val() == 'label'
    return

  # depending on whether an item has a pdf destination or not, hide or
  # display the page field in the toc item edit view
  # (relevant on media enrich page)
  $(document).on 'change', '#item_pdf_destination', ->
    if $(this).val() != ''
      $('#item_page_field').hide()
    else
      $('#item_page_field').show()
    return

  # if a toc item is clicked in the toc box, jump to the corresponding time
  # in the video and render edit item view in the action box
  # (relevant on media enrich page)
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

  # clean up action box if editing of item is cancelled
  # (relevant on media enrich page)
  $(document).on 'click', '#cancel-item', ->
    $('#action-placeholder').empty()
    $('#action-container').empty()
    return

  # test external link for item in an external tab
  # (relevant on media enrich page)
  $(document).on 'click', '#item-test-link', ->
    url = $('#item_link').val()
    window.open(url, '_blank')
    return

  # create external item as reference
  # (relevant on media enrich page)
  $(document).on 'click', '#create_external_link', ->
    $('#external_item_form')[0].reset();
    $('#item_link').removeClass('is-invalid')
    $('#item-link-error').empty()
    $('#item_description').removeClass('is-invalid')
    $('#item-description-error').empty()
    $('#newItemModal').modal('show')
    return

  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#item_sort'
  $(document).off 'change', '#item_section_id'
  $(document).off 'change', '#item_pdf_destination'
  $(document).off 'click', '#create_external_link'
  $(document).off 'click', '#item-test-link'
  $(document).off 'click', '#cancel-item'
  $(document).off 'click', '[id^="tocitem-"]'
  return