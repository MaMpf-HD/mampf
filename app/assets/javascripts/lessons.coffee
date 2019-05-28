# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # if any input is given to the lesson form, disable creation of media and
  # issue warning
  $(document).on 'change', '#lesson-form :input', ->
    $('#lesson-basics-warning').show()
    $('#create-new-lesson-medium').addClass('disabled')
    return

  # restore page if creation of new lesson is cancelled
  $(document).on 'click', '#cancel-new-lesson', ->
    $('#new-lesson-area').empty().hide()
    $('.fa-edit').show()
    $('.new-in-lecture').show()
    $('#lecture-preferences-form input').prop('disabled', false)
    $('#lecture-form input').prop('disabled', false)
    $('#lecture-form .selectized').each ->
      this.selectize.enable()
    return

  $(document).on 'click', '.cancel-lesson-edit', ->
    location.reload()
    return

  # add/remove associated tags in the tag selector
  # if sections are selected/deselected
  # this code has to be here, as turbolinks will not remember event handlers
  # from a lesson modal
  sectionSelector = document.getElementById('lesson_section_ids')
  tagSelector = document.getElementById('lesson_tag_ids')

  if sectionSelector? && tagSelector?
    sectionSelectize = sectionSelector.selectize
    tagSelectize = tagSelector.selectize
    # tags and their associated sections are stored in the data-tags attribute
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

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#lesson-form :input'
  $(document).off 'click', '#cancel-new-lesson'
  $(document).off 'click', '.cancel-lesson-edit'
  return
