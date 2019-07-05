# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# update quizzable text for default target selector for remarks

$(document).on 'turbolinks:load', ->

  $(document).on 'change', '[id^="default_target_select_"]', ->
    $.ajax Routes.update_vertex_default_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $(this).data('quizid')
        id: $('#' + this.id + ' option:selected').val()
        vertex_id: $(this).data('vertexid')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # update quizzable text for branching selectors for questions

  $(document).on 'change', '[id^="branching_select-"]', ->
    $.ajax Routes.update_branching_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $(this).data('quizid')
        vertex_id: $(this).val()
        id: this.id
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # change button 'Ziele ändern' to 'verwerfen' after vertex body is revealed

  $(document).on 'shown.bs.collapse', '[id^="collapse-vertex-"]', ->
    $('#targets-vertex-' + $(this).data('vertex')).empty()
      .append(I18n.t('buttons.discard'))
    return

  # change button 'verwerfen' back to 'Ziele ändern' and rerender vertex body
  # after vertex body is hidden

  $(document).on 'hidden.bs.collapse', '[id^="collapse-vertex-"]', ->
    $.ajax Routes.update_vertex_body_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        vertex_id: $(this).data('vertex')
        quiz_id: $(this).data('quiz')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # render quizzable modal after 'bearbeiten' is clicked in vertex header

  $(document).on 'click', '[id^="edit-vertex-content-"]', ->
    $.ajax Routes.fill_quizzable_modal_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: $(this).data('id')
        type: $(this).data('type')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # reload current page after quizzable edit modal is closed

  $(document).on 'hidden.bs.modal', '#quizzableModal', ->
    location.reload()
    return

  # render modal for quizzable duplication dialogue

  $(document).on 'click', '#button-reassign', ->
    $.ajax Routes.fill_reassign_modal_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: $(this).data('id')
        type: $(this).data('type')
        in_quiz: $('#quiz_id_js').length == 1
        quiz_id: $('#quiz_id_js').attr('value')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # highlight neighbouring vertices rows on mouseenter von neighbour span

  $(document).on 'mouseenter', '[id^="neighbours-"]', ->
    neighbours = $(this).data('neighbours')
    id =  $(this).data('id')
    for n in neighbours
      vertex = if n[0] == -1 then id else n[0]
      header = $('#vertex-heading-' + vertex)
      color = $(header).data('color')
      if n[0] == -1
        $(header).removeClass(color).addClass('bg-orange')
      else
        if n[1]
          $(header).removeClass(color).addClass('bg-green-lighten-2')
        else
          $(header).removeClass(color).addClass('bg-red-lighten-2')
    return

  # remove highlighting of neighbouring vertices rows on mouseleave of neighbour
  # span

  $(document).on 'mouseleave', '[id^="neighbours-"]', ->
    neighbours = $(this).data('neighbours')
    id =  $(this).data('id')
    for n in neighbours
      vertex = if n[0] == -1 then id else n[0]
      header = $('#vertex-heading-' + vertex)
      color = $(header).data('color')
      if n[0] == -1
        $(header).removeClass('bg-orange').addClass(color)
      else
        if n[1]
          $(header).removeClass('bg-green-lighten-2').addClass(color)
        else
          $(header).removeClass('bg-red-lighten-2').addClass(color)
    return

  $(document).on 'mouseenter', '[id^="result-quizzable-"]', ->
    $('#quizzesPreviewHeader').show()
    $(this).addClass('bg-orange-lighten-4')
    $.ajax Routes.fill_quizzable_preview_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: $(this).data('id')
        type: $(this).data('type')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'mouseleave', '[id^="result-quizzable-"]', ->
    $(this).removeClass('bg-orange-lighten-4')
    return

  $(document).on 'mouseleave', '#quizzableSearchResults', ->
    $('#quizzablePreview').empty()
    $('#quizzesPreviewHeader').hide()
    return

  $(document).on 'mouseenter', '#selectedQuizzablesColumn', ->
    $('#quizzablePreview').empty()
    $('#quizzesPreviewHeader').hide()
    return


  $(document).on 'click', '[id^="result-quizzable-"]', ->
    $(this).removeClass('bg-orange-lighten-4').addClass('bg-green-lighten-4')
    $.ajax Routes.render_import_vertex_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $('#new_vertex').data('quiz')
        id: $(this).data('id')
        type: $(this).data('type')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#cancel-import-vertex', ->
    $('#quizzablePreview').empty()
    $('[id^="result-quizzable-"]').removeClass('bg-green-lighten-4')
    importTab = document.getElementById('import-vertex-tab')
    importTab.dataset.selected = '[]'
    $.ajax Routes.cancel_import_vertex_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $('#new_vertex').data('quiz')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#submit-import-vertex', ->
    quizId = $('#new_vertex').data('quiz')
    importTab = document.getElementById('import-vertex-tab')
    selected = JSON.parse(importTab.dataset.selected)
    console.log 'Hier'
    $.ajax Routes.quiz_vertices_path(quiz_id: quizId),
      type: 'POST'
      dataType: 'script'
      data: {
        vertex: {
          sort: 'import'
          quizzable_ids: selected
        }
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '[id^="default_target_select_"]'
  $(document).off 'change', '[id^="branching_select-"]'
  $(document).off 'change', '#new_vertex_type_select'
  $(document).off 'change', '#new_vertex_quizzable_select'
  $(document).off 'shown.bs.collapse', '[id^="collapse-vertex-"]'
  $(document).off 'hidden.bs.collapse', '[id^="collapse-vertex-"]'
  $(document).off 'click', '[id^="edit-vertex-content-"]'
  $(document).off 'hidden.bs.modal', '#quizzableModal'
  $(document).off 'click', '#button-reassign'
  $(document).off 'mouseenter', '[id^="neighbours-"]'
  $(document).off 'mouseleave', '[id^="neighbours-"]'
  $(document).off 'mouseenter', '[id^="result-quizzable-"]'
  $(document).off 'mouseleave', '[id^="result-quizzable-"]'
  $(document).off 'mouseleave', '#quizzableSearchResults'
  $(document).off 'click', '[id^="result-quizzable-"]'
  $(document).off 'click', '#cancel-import-vertex'
  $(document).off 'click', '#submit-import-vertex'
  $(document).off 'mouseenter', '#selectedQuizzablesColumn'
  return