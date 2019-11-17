# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # if any input is given to the lesson form, disable creation of media and
  # issue warning
  $(document).on 'change', '#lesson-form :input', ->
    $('#lesson-basics-warning').show()
    $('#create-new-lesson-medium').hide()
    return

  # restore page if creation of new lesson is cancelled
  $(document).on 'click', '#cancel-new-lesson', ->
    $('#new-lesson-area').empty().hide()
    $('.fa-edit').show()
    $('.new-in-lecture').show()
    $('[data-toggle="collapse"]').removeClass('disabled')
    return

  $(document).on 'click', '.cancel-lesson-edit', ->
    location.reload()
    return

  # add/remove associated tags in the tag selector
  # if sections are selected/deselected

  sectionSelector = document.getElementById('lesson_section_ids')
  tagSelector = document.getElementById('lesson_tag_ids')

  # add/remove associated tags in the tag selector
  # if sections are selected/deselected
  if sectionSelector? && tagSelector?
    sectionSelectize = sectionSelector.selectize
    # tags and their associated sections are stored in the data-tags attribute
    tags = $(sectionSelector).data('tags')

    sectionSelectize.on 'item_remove', (value) ->
      tagSelectize = tagSelector.selectize
      removeTags = (tags.filter (x) -> x.section.toString() == value.toString())[0].tags
      ids = removeTags.map (x) -> x[0]
      for i in ids
        tagSelectize.removeItem(i)
      tagSelectize.refreshItems()
      tagSelectize.refreshOptions(false)
      return

    sectionSelectize.on 'item_add', (value) ->
      tagSelectize = tagSelector.selectize
      addTags = (tags.filter (x) -> x.section.toString() == value.toString())[0].tags
      for i in addTags
        tagSelectize.addItem(i[0])
      tagSelectize.refreshItems()
      tagSelectize.refreshOptions(false)
      return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#lesson-form :input'
  $(document).off 'click', '#cancel-new-lesson'
  $(document).off 'click', '.cancel-lesson-edit'
  return
