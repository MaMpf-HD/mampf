# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#lecture-form :input').on 'change', ->
    $('#lecture-basics-warning').show()
    if $('#lecture_absolute_numbering').prop('checked')
      $('#start-section-input').show()
      $('#lecture_start_section').prop('disabled', false)
    else
      $('#start-section-input').hide()
      $('#lecture_start_section').prop('disabled', true)
    additionalTags = document.getElementById('lecture_additional_tag_ids').selectize.getValue()
    disabledTags = document.getElementById('lecture_disabled_tag_ids').selectize.getValue()
    $.ajax Routes.list_lecture_tags_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        additional_tags: JSON.stringify(additionalTags)
        disabled_tags: JSON.stringify(disabledTags)
      }
    return

  $('#lecture-basics-cancel').on 'click', ->
    location.reload()
    return

  $('#lecture-additional-tags-links').on 'click', ->
    if $('#lecture-additional-tag-list').data('show') == 0
      $('#lecture-additional-tag-list').data('show', 1).show()
      $(this).text('Links ausblenden')
    else
      $('#lecture-additional-tag-list').data('show', 0).hide()
      $(this).text('Links einblenden')
    return

  $('#lecture-disabled-tags-links').on 'click', ->
    if $('#lecture-disabled-tag-list').data('show') == 0
      $('#lecture-disabled-tag-list').data('show', 1).show()
      $(this).text('Links ausblenden')
    else
      $('#lecture-disabled-tag-list').data('show', 0).hide()
      $(this).text('Links einblenden')
    return
  return
