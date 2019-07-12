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

  # highlight 'Ungespeicherte Änderungen' if quiz top is selected

  $(document).on 'change', '#quiz-top-select', ->
    $('#quiz-basics-options').removeClass("no_display")
    $('#quiz-basics-warning').removeClass("no_display")
    return

  # highlight 'Ungespeicherte Änderungen' if quiz level is changed

  $(document).on 'change', '#level', ->
    $('#quiz-basics-options').removeClass("no_display")
    $('#quiz-basics-warning').removeClass("no_display")
    return


  # restore status quo if editing of quiz basics is cancelled

  $(document).on 'click', '#quiz-basics-cancel', (evt) ->
    $.ajax Routes.cancel_quiz_basics_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        quiz_id: $(this).data('id')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
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
        name: 'dagre'
        nodeDimensionsIncludeLabels: false
#        circle: true
#        grid: true
#        rows: 5
#        columns: 5
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


  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '[id^="toggle_results-"]'
  $(document).off 'change', '#quiz-top-select'
  $(document).off 'change', '#level'
  $(document).off 'click', '#quiz-basics-cancel'
  $(document).off 'click', '[id^="reveal-explanation-"]'
  $(document).off 'click', '[id^="reveal-hint-"]'
  return