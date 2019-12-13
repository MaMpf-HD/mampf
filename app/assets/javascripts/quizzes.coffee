$(document).on 'turbolinks:load', ->

  # toggle results display for answered questions in an active quiz

  $(document).on 'click', '[id^="toggle_results-"]', ->
    round_id = this.id.replace('toggle_results-','')
    status = $(this).data('status')
    color = $(this).data('color')
    if status == 'reduced'
      $('#reduced-' + round_id).hide 400
      $('#body-' + round_id).addClass color
      $('#toggle_message-' + round_id).empty().append($(this).data('hide'))
      $('#results-' + round_id).show 800, ->
        $('#toggle_results-' + round_id).data 'status', 'extended'
        return
    else
      $('#results-' + round_id).hide 800
      $('#body-' + round_id).removeClass('bg-correct').removeClass 'bg-incorrect'
      $('#toggle_message-' + round_id).empty().append($(this).data('details'))
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
            'border-color': 'data(bordercolor)'
            'border-width': 'data(borderwidth)'
            'shape': 'data(shape)'
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
            'border-color': 'blue'
            'border-width': 4
        }
        {
          selector: '.edgeselected'
          style:
            'line-color': 'blue'
            'width': 4
        }
      ]
      userZoomingEnabled: zoomable
      minZoom: 0.2
      maxZoom: 5
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
        # generic case: selection of a vertex (not root vertex, not default
        # target)
        if $cyContainer.data('root') != 'select' and
           $cyContainer.data('vertextarget') != 'select'
          # ignore if start vertex of end vertex is clicked
          return if id in ['-1','-2']
          $('#deleteEdgeButtons').hide()
          # remove highlighting of previous selections (vertices and nodes)
          cy.nodes().removeClass('selected')
          cy.edges().removeClass('edgeselected')
          # highlight selection
          node.addClass('selected')
          # store vertex id in cytoscape container
          $cyContainer.data('vertex', id)
          # store default target of vertex in cytoscape container
          defaultTarget = node.data('defaulttarget')
          $('#cy').data('defaulttarget', defaultTarget)
          # render a preview of the quizzable that is associated to the clicked
          # vertex
          $.ajax Routes.render_vertex_quizzable_path(),
            type: 'GET'
            dataType: 'script'
            data: {
              quiz_id: $cyContainer.data('quiz')
              id: id
            }
            error: (jqXHR, textStatus, errorThrown) ->
              console.log("AJAX Error: #{textStatus}")
        # non-generic case: selection of graph root
        else if $cyContainer.data('root') == 'select'
          return if id in ['-1','-2']
          quizId = $cyContainer.data('quiz')
          # update quiz root in DB
          $.ajax Routes.set_quiz_root_path(quizId),
            type: 'POST'
            dataType: 'script'
            data: {
              root: id
            }
            error: (jqXHR, textStatus, errorThrown) ->
              console.log("AJAX Error: #{textStatus}")
        # non-generic case: selection of default target for a vertex
        else
          # ignore if start vertex is clicked
          return if id == '-2'
          # remove previously selected default edge that did not exist
          # before as edge
          newSelectedEdge = cy.filter (element, i) ->
            element.isEdge() and element.data('selected_default_edge') and not
            element.data('old')
          cy.remove(newSelectedEdge)
          # restore previously selected default edge that existed before
          oldSelectedEdge = cy.filter (element, i) ->
            element.isEdge() and element.data('selected_default_edge') and
            element.data('old')
          oldSelectedEdge.data('color', oldSelectedEdge.data('oldcolor'))
          oldSelectedEdge.data('selected_default_edge', false)
          oldSelectedEdge.data('defaultedge', false)
          # remove current default edge from selected source vertex
          source = $('#cy').data('vertex')
          previousDefault = cy.filter (element, i) ->
            element.isEdge() and element.data('source') == source and
            element.data('defaultedge')
          cy.remove previousDefault
          # if an edge already exists between selected source and target vertex,
          # just change the color, mark it as default edge and store stale data
          duplicate = cy.filter (element, i) ->
            element.isEdge() and element.data('id') == source + '-' + id
          if duplicate.length > 0
            oldColor = duplicate.data('color')
            duplicate.data('color', 'green')
            duplicate.data('selected_default_edge', true)
            duplicate.data('oldcolor', oldColor)
            duplicate.data('old', true)
          # otherwise, create new default edge from source vertex to target
          # vertex
          else
            cy.add
              group: 'edges'
              data:
                id: source + '-' + id
                source: source
                target: id
                color: 'green'
                selected_default_edge: true
          # show save default target button and store source and target in it
          $('#saveDefaultTarget').show()
          $('#saveDefaultTarget').data('source', source)
          $('#saveDefaultTarget').data('target', id)
        return

      cy.on 'tap', 'edge', (evt) ->
        # determine source and target vertex
        edge = evt.target
        source = edge.data('source')
        target = edge.data('target')
        return if source == '-2'
        if $cyContainer.data('root') != 'select' and
           $cyContainer.data('vertextarget') != 'select'
          edge = evt.target
          id = edge.id()
          # layout changes
          $('#vertex-buttons').empty()
          $('.basicQuizButton').hide()
          $('#quizzableArea').empty()
          $('#vertexActionArea').empty()
          $('html, body').animate scrollTop: 0
          # show delete edge button and store source and target in it
          $('#deleteEdgeButtons').show()
          $('#deleteEdge').data('source', source)
          $('#deleteEdge').data('target', target)
          # remove highlighting of previously selections
          cy.nodes().removeClass('selected')
          cy.edges().removeClass('edgeselected')
          edge.addClass('edgeselected')
        return

  $(document).on 'click', '#selectQuizRoot', ->
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
    location.reload(true) if $(this).data('mode') == 'reassigned'
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

  $(document).on 'click', '#cancelVertexEdit', ->
    $('#vertexTargetArea').empty()
    $('#vertex-buttons').empty()
    $('#quiz_buttons').show()
    $('#vertexActionArea').empty()
    cy.nodes().removeClass('selected')
    $('#cy').data('vertex', '')
    return

  $(document).on 'click', '#selectDefaultTarget', ->
    $('#cy').data('vertextarget', 'select')
    $('#vertexTargetArea').empty()
    $('#vertex-buttons').hide()
    $('#selectTargetInfo').show()
    return

  $(document).on 'click', '#cancelDefaultTarget', ->
    # remove selected default edge
    selectedDefaultEdge = cy.filter (element, i) ->
      element.isEdge() and element.data('selected_default_edge')
    cy.remove(selectedDefaultEdge)
    # restore previous default edge
    source = $('#cy').data('vertex')
    defaulttarget = $('#cy').data('defaulttarget')
    previousDefault = cy.filter (element, i) ->
      element.isEdge() and element.data('source') == source and
      element.data('defaultedge')
    if previousdefault.length == 0 && defaulttarget != 0
      cy.add
        group: 'edges'
        data:
          id: source + '-' + defaulttarget
          source: source
          target: defaulttarget
          color: '#32cd32'
          defaultedge: true
    # layout changes
    $('#selectTargetInfo').hide()
    $('#saveDefaultTarget').hide()
    $('#vertex-buttons').show()
    # clean up data
    $('#cy').data('vertextarget', '')
    return

  $(document).on 'click', '#saveDefaultTarget', ->
    $('#selectTargetInfo').hide()
    $('#saveDefaultTarget').hide()
    $('#vertex-buttons').show()
    # save default edge in cy graph, adjust color
    defaultEdge = cy.filter (element, i) ->
      element.isEdge() and element.data('selected_default_edge')
    defaultEdge.data('selected_default_edge', false)
    defaultEdge.data('color', '#32cd32')
    defaultEdge.data('defaultedge', true)
    $('#cy').data('vertextarget', '')
    # transmit changes to DB
    quizId = $('#cy').data('quiz')
    $.ajax Routes.update_default_target_path(quizId),
      type: 'POST'
      dataType: 'script'
      data: {
        source: $(this).data('source')
        target: $(this).data('target')
      }
    return

  $(document).on 'click', '#cancelDeleteEdge', ->
    $('#deleteEdgeButtons').hide()
    $('#quiz_buttons').show()
    $('.basicQuizButton').show()
    cy.edges().removeClass('edgeselected')
    return

  $(document).on 'click', '#deleteEdge', ->
    quizId = $('#cy').data('quiz')
    marked = cy.$('.edgeselected')
    # if edge marked for selection was default edge, refresh default
    # target for source vertex
    if marked.data('defaultedge')
      cy.$('#' + marked.data('source')).data('defaulttarget', 0)
    marked.remove()
    # transmit deletion to DB
    $.ajax Routes.delete_edge_path(quizId),
      type: 'DELETE'
      dataType: 'script'
      data: {
        source: $(this).data('source')
        target: $(this).data('target')
      }
    # layout changes
    $('#deleteEdgeButtons').hide()
    $('#quiz_buttons').show()
    $('.basicQuizButton').show()
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
  $(document).off 'click', '#cancelVertexEdit'
  $(document).off 'click', '#selectDefaultTarget'
  $(document).off 'click', '#cancelDefaultTarget'
  $(document).off 'click', '#saveDefaultTarget'
  $(document).off 'click', '#cancelDeleteEdge'
  $(document).off 'click', '#deleteEdge'
  return