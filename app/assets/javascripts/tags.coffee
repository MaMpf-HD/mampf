# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  tagTable = document.getElementById('tagTable')
  if inputTag?
    tagsWithId = JSON.parse(tagTable.dataset.tags)
    ids = tagsWithId.map (item) -> item.id
    sifter = new Sifter(tagsWithId)

  displayResults = ->
    searchString = $('#inputTag').val()
    selectedCourses = $('#inputCourses').val().map (item) -> parseInt(item)
    result = sifter.search(searchString,
      fields: [ 'title' ]
      sort: [ {
        field: 'title'
        direction: 'asc'
      } ])
    matchedIds = result.items.map (item) -> tagsWithId[item.id].id
    for id in ids
      row = document.getElementById('row-tag-' + id)
      courses = JSON.parse(row.dataset.courses).map (item) -> parseInt(item)
      if (id in matchedIds) && ($(courses).not($(courses).not($(selectedCourses)))).length > 0
        $(row).show()
      else
        $(row).hide()
    return

  $('#inputTag').on 'keyup', ->
    displayResults()
    return

  $('#inputCourses').on 'change', ->
    displayResults()
    return

  $('#tag-form :input').on 'change', ->
    $('#tag-basics-warning').show()
    courseSelector = document.getElementById('tag_course_ids')
    selectedCourses = courseSelector.selectize.getValue().map (item) -> parseInt(item)
    editableCourses = JSON.parse(courseSelector.dataset.editable).map (item) -> parseInt(item)
    if ($(editableCourses).not($(editableCourses).not($(selectedCourses)))).length > 0
      $('#editable-tags').show()
      $('#non-editable-tags').hide()
    else
      $('#editable-tags').hide()
      relatedTagSelector = document.getElementById('tag_related_tag_ids')
      oldValue = JSON.parse(relatedTagSelector.dataset.restore).map (x) -> x.toString()
      console.log oldValue
      console.log relatedTagSelector
      relatedTagSelector.selectize.setValue(oldValue, true)
      $('#non-editable-tags').show()
    return

  $('#tag-basics-cancel').on 'click', ->
    location.reload()
    return

  return
