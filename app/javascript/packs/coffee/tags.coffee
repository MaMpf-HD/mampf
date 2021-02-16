# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
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
  $('[id^="tag-form-"]').on 'change', ->
    id = this.dataset.id
    $('#tag-basics-warning-' + id).show()
    $('#new-tag-button').remove()
    $('#new-tag-defunct').show()
    return

  # reload page if tag editing is cancelled
  $('[id^="tag-basics-cancel-"]').on 'click', ->
    location.reload(true)
    return

  # prepare action box when related tags are edited
  $('#selectRelatedTags').on 'click', ->
    $('#selectRelatedTagsForm').show()
    $('#tagActionTypeRelated').show()
    $(this).hide()
    $('#selectTagRealizations').hide()
    $('#tagActionHeader').hide()
    return

  # prepare action box when related tags are edited
  $('#selectTagRealizations').on 'click', ->
    $('#selectTagRealizationsForm').show()
    $('#tagActionTypeRealizations').show()
    $(this).hide()
    $('#selectRelatedTags').hide()
    $('#tagActionHeader').hide()
    return

  $('#cancelSelectRelatedTags').on 'click', ->
    $('#selectRelatedTagsForm').hide()
    $('#tagActionTypeRelated').hide()
    $('#tagActionHeader').show()
    $('#selectRelatedTags').show()
    $('#selectTagRealizations').show()
    return

  $('#cancelSelectRealizations').on 'click', ->
    $('#selectTagRealizationsForm').hide()
    $('#tagActionTypeRealizations').hide()
    $('#tagActionHeader').show()
    $('#selectTagRealizations').show()
    $('#selectRelatedTags').show()
    return

  # container for cytoscape view
  $cyContainer = $('#cy')
  if $cyContainer.length > 0 && $cyContainer.data('type') == 'tag'
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
        window.location.href = Routes.tag_path(node.id(), locale: $cyContainer.data('locale'))
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

  $(document).on 'click', '.cancel-section-association', ->
    location.reload(true)
    return

  $erdbeereTags = $('#erdbeereTags')
  if $erdbeereTags.length > 0
    $.ajax Routes.find_erdbeere_tags_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        sort: $erdbeereTags.data('sort')
        id: $erdbeereTags.data('id')
      }
    return

  $erdbeereRealizations = $('.erdbeere-realization')
  $erdbeereRealizations.each ->
    $.ajax Routes.display_erdbeere_info_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        sort: $(this).data('sort')
        id: $(this).data('id')
      }
    return

  $selectTagRealizations = $('#selectTagRealizationsForm')
  if $selectTagRealizations.length > 0
    $.ajax Routes.fill_realizations_select_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: $selectTagRealizations.data('id')
      }
    return



  return
# clean up before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#new-tag-button'
  $(document).off 'change', '#tag_identified_tag_id'
  $(document).off 'click', '.cancel-section-association'
  $('#cy').empty()
  return
