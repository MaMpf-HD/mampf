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

  # render quizzable modal after 'bearbeiten' is clicked in vertex header

  $(document).on 'click', '[id^="edit-vertex-content-"]', ->
    $.ajax Routes.fill_quizzable_area_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: $(this).data('id')
        type: $(this).data('type')
        vertex: $(this).data('vertex')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # reload current page after quizzable edit modal is closed

  $(document).on 'hidden.bs.modal', '#quizzableModal', ->
    location.reload(true)
    return

  # render modal for quizzable duplication dialogue

  $(document).on 'click', '#button-reassign', ->
    $.ajax Routes.fill_reassign_modal_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: $(this).data('id')
        type: $(this).data('type')
        rights: $(this).data('rights')
        in_quiz: $('#cy').length == 1
        quiz_id: $('#cy').data('quiz')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  # $(document).on 'click', '#cancel-import-vertex', ->
  #   $('#mediumPreview').empty()
  #   $('[id^="row-medium-"]').removeClass('bg-green-lighten-4')
  #   importTab = document.getElementById('import-vertex-tab')
  #   importTab.dataset.selected = '[]'
  #   $.ajax Routes.cancel_import_vertex_path(),
  #     type: 'GET'
  #     dataType: 'script'
  #     data: {
  #       quiz_id: $('#new_vertex').data('quiz')
  #     }
  #     error: (jqXHR, textStatus, errorThrown) ->
  #       console.log("AJAX Error: #{textStatus}")
  #   return

  # $(document).on 'click', '#submit-import-vertex', ->
  #   quizId = $('#new_vertex').data('quiz')
  #   importTab = document.getElementById('import-vertex-tab')
  #   selected = JSON.parse(importTab.dataset.selected)
  #   $.ajax Routes.quiz_vertices_path(quiz_id: quizId),
  #     type: 'POST'
  #     dataType: 'script'
  #     data: {
  #       vertex: {
  #         sort: 'import'
  #         quizzable_ids: selected
  #       }
  #     }
  #     error: (jqXHR, textStatus, errorThrown) ->
  #       console.log("AJAX Error: #{textStatus}")
  #   return

  $(document).on 'click', '#cancelNewVertex', ->
    $('#quiz_buttons').show()
    $('#new_vertex').hide()
    $('html, body').animate scrollTop: 0
    return

  $(document).on 'click', '#targetsFromVertex', ->
    quizId = $(this).data('quiz')
    vertexId = $(this).data('vertex')
    $.ajax Routes.edit_vertex_targets_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: quizId
        id: vertexId
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#cancelVertexTargets', ->
    $('#vertexTargetArea').empty()
    $('html, body').animate scrollTop: 0
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '[id^="default_target_select_"]'
  $(document).off 'change', '[id^="branching_select-"]'
  $(document).off 'click', '[id^="edit-vertex-content-"]'
  $(document).off 'hidden.bs.modal', '#quizzableModal'
  $(document).off 'click', '#button-reassign'
  # $(document).off 'click', '#cancel-import-vertex'
  # $(document).off 'click', '#submit-import-vertex'
  $(document).off 'click', '#cancelNewVertex'
  $(document).off 'click', '#targetsFromVertex'
  $(document).off 'click', '#cancelVertexTargets'
  return