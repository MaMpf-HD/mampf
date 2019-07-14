$(document).on 'turbolinks:load', ->

  # toggle results display for answered questions in an active quiz

  $(document).on 'click', '[id^="toggle_results-"]', ->
    round_id = this.id.replace('toggle_results-','')
    status = $(this).data('status')
    color = $(this).data('color')
    if status == 'reduced'
      $('#reduced-' + round_id).hide 400
      $('#body-' + round_id).addClass color
      $('#toggle_message-' + round_id).empty().append(I18n.t('admin.quiz.hide'))
      $('#results-' + round_id).show 800, ->
        $('#toggle_results-' + round_id).data 'status', 'extended'
        return
    else
      $('#results-' + round_id).hide 800
      $('#body-' + round_id).removeClass('bg-correct').removeClass 'bg-incorrect'
      $('#toggle_message-' + round_id).empty().append(I18n.t('basics.details'))
      $('#reduced-' + round_id).fadeIn 800, ->
        $('#toggle_results-' + round_id).data 'status', 'reduced'
        return
    return

  # reveal explanations for answers

  $(document).on 'click', '[id^="reveal-explanation-"]', ->
    $('#' + this.id.replace('reveal-','')).removeClass("no_display")
    $('#' + this.id.replace('reveal-explanation','feedback')).removeClass("no_display")
    $(this).remove()
    return

  # reveal hint for solution

  $(document).on 'click', '[id^="reveal-hint-"]', ->
    $('#' + this.id.replace('reveal-','')).removeClass("no_display")
    $(this).remove()
    return

   # container for cytoscape view
  $cyContainer = $('#cy')
  if $cyContainer.length > 0 && $cyContainer.data('type') == 'quiz'
    if $cyContainer.data('linear')
      layout = 'circle'
    else
      layout = 'breadthfirst'
    if $cyContainer.data('mode') == 'view'
      zoomable = false
      ungrabbable = true
      pannable = false
    else
      zoomable = true
      ungrabbable = false
      pannable = true
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
            'line-color': 'data(color)'
            'curve-style': 'bezier'
            'control-point-distances' : '-50 50 -50'
            'mid-target-arrow-color': 'data(color)'
            'mid-target-arrow-shape': 'triangle'
            'arrow-scale': 2
        }
        {
          selector: '.hovering'
          style:
            'font-size': '2em'
            'background-color': 'blue'
        }
        {
          selector: '.selected'
          style:
            'font-size': '2em'
            'background-color': 'green'
            'color': 'green'
        }
      ]
      userZoomingEnabled: zoomable
      autoungrabify: ungrabbable
      userPanningEnabled: pannable
      layout:
        name: layout
        fit: true
        directed: false)
    if $cyContainer.data('mode') != 'view'
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
        id = node.id()
        if id not in ['-1','-2']
          if $cyContainer.data('root') != 'select'
            $.ajax Routes.render_vertex_quizzable_path(),
              type: 'GET'
              dataType: 'script'
              data: {
                quiz_id: $cyContainer.data('quiz')
                id: id
              }
              error: (jqXHR, textStatus, errorThrown) ->
                console.log("AJAX Error: #{textStatus}")
          else
            quizId = $cyContainer.data('quiz')
            $.ajax Routes.set_quiz_root_path(quizId),
              type: 'POST'
              dataType: 'script'
              data: {
                root: id
              }
              error: (jqXHR, textStatus, errorThrown) ->
                console.log("AJAX Error: #{textStatus}")
        return

  $(document).on 'click', '#selectQuizRoot', ->
    console.log 'Hier'
    $('#cy').data('root', 'select')
    $('.basicQuizButton').hide()
    $('#selectRootInfo').show()
    return

  $(document).on 'click', '#cancelQuizRoot', ->
    $('#cy').data('root', '')
    $('.basicQuizButton').show()
    $('#selectRootInfo').hide()
    return

  $(document).on 'click', '#selectQuizLevel', ->
    $('#cy').data('root', 'select')
    $('.basicQuizButton').hide()
    $('#quizLevelForm').show()
    return

  $(document).on 'change', '.quiz-level', ->
    level = $(this).data('level')
    quizId = $(this).data('quiz')
    $.ajax Routes.set_quiz_level_path(quizId),
      type: 'POST'
      dataType: 'script'
      data: {
        level: level
      }
    return

  $(document).on 'click', '#cancelQuizLevel', ->
    $('.basicQuizButton').show()
    $('#quizLevelForm').hide()
    return

  $(document).on 'click', '#finishQuizzableEditing', ->
    location.reload() if $(this).data('mode') == 'reassigned'
    $('#quizzableArea').empty()
    $('#quizGraphArea').show()
    $.ajax Routes.render_vertex_quizzable_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $('#cy').data('quiz')
        id: $(this).data('vertex')
      }
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '[id^="toggle_results-"]'
  $(document).off 'click', '[id^="reveal-explanation-"]'
  $(document).off 'click', '[id^="reveal-hint-"]'
  $(document).off 'click', '#selectQuizRoot'
  $(document).off 'click', '#cancelQuizRoot'
  $(document).off 'click', '#selectQuizLevel'
  $(document).off 'change', '.quiz-level'
  $(document).off 'click', '#cancelQuizLevel'
  return