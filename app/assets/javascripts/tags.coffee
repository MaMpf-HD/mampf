# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  tagTable = document.getElementById('tagTable')
  inputCourses = document.getElementById('inputCourses')
  inputTag = document.getElementById('inputTag')
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

  $('[id^="tag-form-"] :input').on 'change', ->
    id = this.dataset.id
    $('#tag-basics-warning-' + id).show()
    return

  $('[id^="tag-basics-cancel-"]').on 'click', ->
    location.reload()
    return

  $('#tags-edited-courses').on 'click', ->
    inputCourses.selectize.setValue(JSON.parse(this.dataset.courses))
    return

  $('#tags-all-courses').on 'click', ->
    inputCourses.selectize.setValue(JSON.parse(this.dataset.courses))
    return

  $('#tags-no-courses').on 'click', ->
    inputCourses.selectize.setValue()
    return

  $('#selectRelatedTags').on 'click', ->
    $('#selectRelatedTagsForm').show()
    $('#tagActionType').show()
    $(this).hide()
    return

  # container for cytoscape view for standard users
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
      node = evt.target;
      node.addClass('hovering')

    cy.on 'mouseout', 'node', (evt) ->
      node = evt.target;
      node.removeClass('hovering')

    cy.on 'tap', 'node', (evt) ->
      node = evt.target;
      window.location.href = Routes.tag_path(node.id())

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

  # container for cytoscape view for standard users
  $cyEditContainer = $('#cyEdit')
  if $cyEditContainer.length > 0
    cyEdit = cytoscape(
      container: $cyEditContainer
      elements: $cyEditContainer.data('elements')
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

    cyEdit.on 'mouseover', 'node', (evt) ->
      node = evt.target;
      node.addClass('hovering')

    cyEdit.on 'mouseout', 'node', (evt) ->
      node = evt.target;
      node.removeClass('hovering')

    cyEdit.on 'tap', 'node', (evt) ->
      node = evt.target;
      window.location.href = Routes.edit_tag_path(node.id())

    # mouseenter over related tag -> colorize cytoscape node
    $('[id^="related-tag_"]').on 'mouseenter', ->
      tagId = $(this).data('id')
      cyEdit.$id(tagId).addClass('selected')
      return

    # mouseleave over related tag -> restore original color of cytoscape node
    $('[id^="related-tag_"]').on 'mouseleave', ->
      tagId = $(this).data('id')
      cyEdit.$id(tagId).removeClass('selected')
      return

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
  return

$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#new-tag-button'
  $('#cy').empty()
  $('#cyEdit').empty()
  return
