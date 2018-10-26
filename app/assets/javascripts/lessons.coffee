# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $(document).on 'change', '#lesson-form :input', ->
    $('#lesson-basics-warning').show()
    $('#create-new-lesson-medium').addClass('disabled')
    return

  $(document).on 'click', '.cancel-lesson', ->
    location.reload()
    return

  $(document).on 'click', '#cancel-new-lesson', ->
    $('#new-lesson-area').empty().hide()
    $('#new_lesson_button').show()
    $('#new_chapter_button').show()
    $('[id^="new_section_button"]').show()
    $('#lecture-form input').prop('disabled', false)
    $('#lecture-form .selectized').each ->
      this.selectize.enable()
    return

  sectionSelector = document.getElementById('lesson_section_ids')
  tagSelector = document.getElementById('lesson_tag_ids')

  if sectionSelector? && tagSelector?
    sectionSelectize = sectionSelector.selectize
    tagSelectize = tagSelector.selectize
    tags = $(sectionSelector).data('tags')

    sectionSelectize.on 'item_remove', (value) ->
      removeTags = (tags.filter (x) -> x.section.toString() == value.toString())[0].tags
      ids = removeTags.map (x) -> x[0]
      for i in ids
        tagSelectize.removeItem(i)
        tagSelectize.removeOption(i)
      tagSelectize.refreshItems()
      tagSelectize.refreshOptions(false)
      return

    sectionSelectize.on 'item_add', (value) ->
      addTags = (tags.filter (x) -> x.section.toString() == value.toString())[0].tags
      for i in addTags
        tagSelectize.addOption({ value: i[0], text: i[1] })
        tagSelectize.addItem(i[0])
      tagSelectize.refreshItems()
      tagSelectize.refreshOptions(false)
      return

  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#lesson-form :input'
  $(document).off 'click', '.cancel-lesson'
  $(document).off 'click', '#cancel-new-lesson'
  return
