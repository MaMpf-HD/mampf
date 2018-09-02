# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#lesson-form :input').on 'change', ->
    $('#lesson-basics-warning').show()
    sections = document.getElementById('lesson_section_ids').selectize.getValue()
    $.ajax Routes.list_lesson_sections_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        section_ids: JSON.stringify(sections)
      }
    return

  $('#lesson-sections-links').on 'click', ->
    if $('#lesson-section-list').data('show') == 0
      $('#lesson-section-list').data('show', 1).show()
      $(this).text('Links ausblenden')
    else
      $('#lesson-section-list').data('show', 0).hide()
      $(this).text('Links einblenden')
    return

  $('#lesson-basics-cancel').on 'click', ->
    location.reload()
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
      tagSelectize.refreshOptions()
      return

    sectionSelectize.on 'item_add', (value) ->
      addTags = (tags.filter (x) -> x.section.toString() == value.toString())[0].tags
      for i in addTags
        tagSelectize.addOption({ value: i[0], text: i[1] })
        tagSelectize.addItem(i[0])
      tagSelectize.refreshItems()
      tagSelectize.refreshOptions()
      return
  return
