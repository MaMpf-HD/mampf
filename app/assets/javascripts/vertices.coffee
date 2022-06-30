# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbo:load', ->

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
    $.ajax Routes.fill_quizzable_area_path($(this).data('id')),
      type: 'GET'
      dataType: 'script'
      data: {
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
    $.ajax Routes.fill_reassign_modal_path($(this).data('id')),
      type: 'GET'
      dataType: 'script'
      data: {
        rights: $(this).data('rights')
        in_quiz: $('#cy').length == 1
        quiz_id: $('#cy').data('quiz')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#cancelNewVertex', ->
    $('#quiz_buttons').show()
    $('#new_vertex').hide()
    $('html, body').animate scrollTop: 0
    return

  $(document).on 'click', '#targetsFromVertex', ->
    quizId = $(this).data('quiz')
    vertexId = $(this).data('vertex')
    $.ajax Routes.edit_vertex_targets_path(quizId),
      type: 'GET'
      dataType: 'script'
      data: {
        vertex_id: vertexId
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'click', '#cancelVertexTargets', ->
    $('#vertexTargetArea').empty()
    $('html, body').animate scrollTop: 0
    return

  return

# clean up everything before turbo caches
$(document).on 'turbo:before-cache', ->
  $(document).off 'change', '[id^="default_target_select_"]'
  $(document).off 'change', '[id^="branching_select-"]'
  $(document).off 'click', '[id^="edit-vertex-content-"]'
  $(document).off 'hidden.bs.modal', '#quizzableModal'
  $(document).off 'click', '#button-reassign'
  $(document).off 'click', '#cancelNewVertex'
  $(document).off 'click', '#targetsFromVertex'
  $(document).off 'click', '#cancelVertexTargets'
  return