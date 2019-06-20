# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  # set up tag search in administration mode using Sifter plugin
  tagTable = document.getElementById('tagTable')
  inputCourses = document.getElementById('inputCourses')
  inputTag = document.getElementById('inputTag')
  if inputTag?
    tagsWithId = JSON.parse(tagTable.dataset.tags)
    ids = tagsWithId.map (item) -> item.id
    sifter = new Sifter(tagsWithId)

  # hide non-matching tag rows in tag indexx table in administration mode
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
      if (id in matchedIds) && (($(courses).not($(courses).not($(selectedCourses)))).length > 0 || (courses.length == 0 && selectedCourses.length ==0))
        $(row).show()
      else
        $(row).hide()
    return

  # refine tag search results on keyup in tag input field
  $('#inputTag').on 'keyup', ->
    displayResults()
    return

  # refine tag search results upon changing of courses
  $('#inputCourses').on 'change', ->
    displayResults()
    return

  # fill courses selector in admin tag search with user's edited courses
  $('#tags-edited-courses').on 'click', ->
    inputCourses.selectize.setValue(JSON.parse(this.dataset.courses))
    return

 # fill courses selector in admin tag search with all courses
  $('#tags-all-courses').on 'click', ->
    inputCourses.selectize.setValue(JSON.parse(this.dataset.courses))
    return

  # fill courses selector in admin tag with no courses at all
  $('#tags-no-courses').on 'click', ->
    inputCourses.selectize.setValue()
    return

  # issue a warning if tag form has changed
  $('[id^="tag-form-"] :input').on 'change', ->
    id = this.dataset.id
    $('#tag-basics-warning-' + id).show()
    $('#new-tag-button').remove()
    $('#new-tag-defunct').show()
    return

  # reload page if tag editing is cancelled
  $('[id^="tag-basics-cancel-"]').on 'click', ->
    location.reload()
    return

  # prepare action box when related tags are edited
  $('#selectRelatedTags').on 'click', ->
    $('#selectRelatedTagsForm').show()
    $('#tagActionType').show()
    $(this).hide()
    $('#tagActionHeader').hide()
    return

  $('#cancelSelectRelatedTags').on 'click', ->
    $('#selectRelatedTagsForm').hide()
    $('#tagActionType').hide()
    $('#tagActionHeader').show()
    $('#selectRelatedTags').show()
    return

  # container for cytoscape view
  $cyContainer = $('#cy')
  if $cyContainer.length > 0
    cy = cytoscape(
      container: $cyContainer
      elements: $cyContainer.data('elements')
      style: [
        {
          selector: 'node'
          style:
            'background-color': 'data(background)'
            'label': 'data(label)'
            'color': 'data(color)'
        }
        {
          selector: 'edge'
          style:
            'width': 3
            'line-color': '#ccc'
            'target-arrow-color': '#ccc'
            'target-arrow-shape': 'triangle'
        }
        {
          selector: '.hovering'
          style:
            'font-size': '2em'
            'background-color': 'green'
            'color': 'green'
        }
        {
          selector: '.selected'
          style:
            'font-size': '2em'
            'background-color': 'green'
            'color': 'green'
        }
      ]
      layout:
        name: 'cose'
        nodeRepulsion: 10000000
        nodeDimensionsIncludeLabels: false)

    cy.on 'mouseover', 'node', (evt) ->
      node = evt.target
      node.addClass('hovering')
      return

    cy.on 'mouseout', 'node', (evt) ->
      node = evt.target
      node.removeClass('hovering')
      return

    cy.on 'tap', 'node', (evt) ->
      node = evt.target
      action = $cyContainer.data('action')
      if action == 'edit'
        window.location.href = Routes.edit_tag_path(node.id())
      else
        window.location.href = Routes.tag_path(node.id(), locale: I18n.locale)
      return

    # mouseenter over related tag -> colorize cytoscape node
    $('[id^="related-tag_"]').on 'mouseenter', ->
      tagId = $(this).data('id')
      cy.$id(tagId).addClass('selected')
      return

    # mouseleave over related tag -> restore original color of cytoscape node
    $('[id^="related-tag_"]').on 'mouseleave', ->
      tagId = $(this).data('id')
      cy.$id(tagId).removeClass('selected')
      return

  # trigger modal for new tag
  $(document).on 'click', '#new-tag-button', ->
    $.ajax Routes.tag_modal_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        related_tag: this.dataset.tag
        course: this.dataset.course
        section: this.dataset.section
        medium: this.dataset.medium
        from: this.dataset.from
      }
    return

  $(document).on 'change', '#tag_identified_tag_id', ->
    if $(this).val()
      $('#identified_tag_titles').show()
      $('#submit_identified_tag').show()
      $.ajax Routes.render_tag_title_path(),
        type: 'GET'
        dataType: 'script'
        data: {
          tag_id: this.dataset.id
          identified_tag_id: $(this).val()
        }
      return
    else
      $('#identified_tag_titles').hide()
      $('#submit_identified_tag').hide()
      $('#identified_tag_titles select').empty()
    return

# clean up before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#new-tag-button'
  $(document).off 'change', '#tag_identified_tag_id'
  $('#cy').empty()
  return
