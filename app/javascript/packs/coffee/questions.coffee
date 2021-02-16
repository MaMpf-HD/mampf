# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class MampfExpression
  constructor: (@expression) ->
    @nerd = nerdamer(@expression)
    @tex = @nerd.toTeX()

  equals: (otherExpression) ->
    @nerd.expand().eq(otherExpression.nerd.expand())

  @parse: (content) ->
    expression = content['question[solution_content[0]]']
    new MampfExpression(expression)

class MampfMatrix
  constructor: (@expression) ->
    @nerd = nerdamer(@expression)
    size = nerdamer('size(' + @expression + ')').text().split(',')
    @rowCount = parseInt(size[1])
    @columnCount = parseInt(size[0])
    @tex = @nerd.toTeX().replace(/vmatrix/g, 'pmatrix')

  equals: (otherMatrix) ->
    return false unless @rowCount == otherMatrix.rowCount
    return false unless @columnCount == otherMatrix.columnCount
    result = true
    for i in [1..@rowCount]
      for j in [1..@columnCount]
        c1 = nerdamer('matget(' + @expression + ',' + (i-1) + ',' + (j-1) + ')')
        c2 = nerdamer('matget(' + otherMatrix.expression + ',' + (i-1) + ',' + (j-1) + ')')
        result = false unless c1.expand().eq(c2.expand())
    result

  @parse: (content) ->
    rowCount = parseInt(content['question[solution_content[row_count]]'])
    columnCount = parseInt(content['question[solution_content[column_count]]'])
    matrix = ''
    for i in [1..rowCount]
      column = '['
      for j in [1..columnCount]
        column += content['question[solution_content[' + i + ',' + j + ']]']
        column += ',' unless j == columnCount
      column += ']'
      matrix += column
      matrix += ',' unless i == rowCount
    expression = 'matrix(' + matrix + ')'
    new MampfMatrix(expression)

class MampfTuple
  constructor: (@expression) ->
    @nerd = nerdamer(@expression)
    @length = parseInt(nerdamer('size(' + @expression + ')'))
    texRaw = @nerd.toTeX()
    @tex = '(' + texRaw.substr(1, texRaw.length - 2) + ')'

  equals: (otherTuple) ->
    return false unless @length == otherTuple.length
    result = true
    for i in [1..@length]
      c1 = nerdamer('vecget(' + @expression + ',' + (i-1) + ')')
      c2 = nerdamer('vecget(' + otherTuple.expression + ',' + (i-1) + ')')
      result = false unless c1.expand().eq(c2.expand())
    result

  @parse: (content) ->
    coeffs = content['question[solution_content[0]]']
    expression = 'vector(' + coeffs + ')'
    new MampfTuple(expression)

class MampfSet
  # note that we assume here that redundant elements have already been removed
  # from the expression (as it is done in the parse class method)
  constructor: (@expression) ->
    @nerd = nerdamer(@expression)
    @size = parseInt(nerdamer('size(' + @expression + ')'))
    texRaw = @nerd.toTeX()
    @tex = '\\{' + texRaw.substr(1, texRaw.length - 2) + '\\}'

  equals: (otherSet) ->
    return false unless @size == otherSet.size
    result = true
    if @size > 0
      for i in [1..@size]
        c1 = nerdamer('vecget(' + @expression + ',' + (i-1) + ')')
        found = false
        for j in [1..@size]
          c2 = nerdamer('vecget(' + otherSet.expression + ',' + (j-1) + ')')
          found = true if c1.expand().eq(c2.expand())
        result = false unless found
    result

  @parse: (content) ->
    elements = content['question[solution_content[0]]'].split(',')
    size = elements.length
    nerds = []
    set = []
    for i in [0..size - 1]
      element = elements[i]
      nerd = nerdamer(element)
      duplicate = false
      for comparedElement in nerds
        duplicate = true if comparedElement.expand().eq(nerd.expand())
      unless duplicate
        nerds.push nerd
        set.push element
    expression = 'vector(' + set.join(',') + ')'
    new MampfSet(expression)

class MampfSolution
  constructor: (@type, @details) ->

  equals: (otherSolution) ->
    return false unless @type == otherSolution.type
    @details.equals(otherSolution.details)

  @parse: (content) ->
    type = content['question[solution_type]']
    details = switch
      when type == 'MampfExpression' then MampfExpression.parse(content)
      when type == 'MampfMatrix' then MampfMatrix.parse(content)
      when type == 'MampfTuple' then MampfTuple.parse(content)
      when type == 'MampfSet' then MampfSet.parse(content)
    new MampfSolution(type, details)

  @fromExpression: (type, expression) ->
    details = switch
      when type == 'MampfExpression' then new MampfExpression(expression)
      when type == 'MampfMatrix' then new MampfMatrix(expression)
      when type == 'MampfTuple' then new MampfTuple(expression)
      when type == 'MampfSet' then new MampfSet(expression)
    new MampfSolution(type, details)

extractSolution = ->
  content  = $('#solution-form').serializeArray().reduce(((obj, item) ->
    obj[item.name] = item.value
    obj
  ), {})
  MampfSolution.parse(content)

compareToSolution = (solutionInput) ->
  solutionString = $('#question_nerd').val()
  type = $('#question_solution_type').val()
  params = $('#solution-form').data('parameters')
  if params
    try
      solutionString = nerdamer(solutionString, params).toString()
    catch err
      solutionString = 'Error'
  solution = MampfSolution.fromExpression(type, solutionString)
  result = solutionInput.equals(solution)
  $('#question_result').val(result)
  $('#question_quiz_result').val(solution.details.tex)
  if result
    $('#quiz_question_crosses').val($('#quiz_question_crosses').data('answer'))
  else
    $('#quiz_question_crosses').val('')
  return

cleanSolutionBox = ->
  $('#solution-error').empty()
  $('#solution-box').hide()
  try
    solutionInput = extractSolution()
  catch err
    solutionInput = 'Syntax Error'
  if solutionInput == 'Syntax Error'
    $('#solution_input_tex').val('')
    $('#solution_input_error').val(solutionInput)
    $('#solution_content_nerd').val('')
    $('#question_result').val(false)
  else
    latex = solutionInput.details.tex
    $('#solution_input_tex').val(latex)
    $('#question_quiz_solution_input').val('$' + latex + '$')
    $('#solution_input_error').val('')
    $('#solution_content_nerd').val(solutionInput.details.expression)
    if $('#question_result').length > 0
      compareToSolution(solutionInput)
  $('#submit-solution').hide()
  return

$(document).on 'turbolinks:load', ->

  $(document).on 'keyup', '#question-basics-edit', ->
    $('#question-basics-options').removeClass("no_display")
    $('#question-basics-warning').removeClass("no_display")
    return


  $(document).on 'change', '#question-basics-edit :input', ->
    $('#question-basics-options').removeClass("no_display")
    $('#question-basics-warning').removeClass("no_display")
    return

  $(document).on 'change', '#questionSort :input', ->
    if $(this).val() == 'mc'
      $('#questionAnswers').show()
      $('#questionSolution').hide()
    else
      $('#questionAnswers').hide()
      $('#questionSolution').show()
    return

# restore status quo if editing of question basics is cancelled

  $(document).on 'click', '#question-basics-cancel', ->
    $.ajax Routes.cancel_question_basics_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        question_id: $(this).data('id')
      }
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'keyup', '#question-solution-edit', ->
    $('#question-solution-options').removeClass("no_display")
    $('#question-solution-warning').removeClass("no_display")
    return


  $(document).on 'change', '#question-solution-edit :input', ->
    return if $(this).hasClass('solutionType')
    $('#question-solution-options').removeClass("no_display")
    $('#question-solution-warning').removeClass("no_display")
    return

# restore status quo if editing of question basics is cancelled

  $(document).on 'click', '#question-solution-cancel', ->
    $.ajax Routes.cancel_solution_edit_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        question_id: $(this).data('id')
      }
    return

  $(document).on 'change', '.solutionType', ->
    type = $(this).data('type')
    questionId = $('#question-solution-edit').data('question')
    $.ajax Routes.set_solution_type_path(questionId),
      type: 'PATCH'
      dataType: 'script'
      data: {
        type: type
      }
    return

  $(document).on 'change', '.rowCount', ->
    rowCount = $(this).data('count')
    columnCount =$('#matrixColumnCount').data('count')
    $('#matrixRowCount').data('count', rowCount)
    for i in [1..4]
      for j in [1..4]
        $entry = $('.matrixEntry[data-row="'+i+'"][data-column="'+j+'"]')
        if i <= rowCount && j <= columnCount
          $entry.show()
        else
          $entry.hide()
    cleanSolutionBox()
    return


  $(document).on 'change', '.columnCount', ->
    columnCount = $(this).data('count')
    rowCount =$('#matrixRowCount').data('count')
    $('#matrixColumnCount').data('count', columnCount)
    for i in [1..4]
      for j in [1..4]
        $entry = $('.matrixEntry[data-row="'+i+'"][data-column="'+j+'"]')
        if i <= rowCount && j <= columnCount
          $entry.show()
        else
          $entry.hide()
    cleanSolutionBox()
    return

  $(document).on 'keyup', '[id^="question_solution_content"]', ->
    cleanSolutionBox()
    return


  $(document).on 'click', '#interpretExpression', ->
    cleanSolutionBox()
    try
      inputSolution = extractSolution()
    catch err
      inputSolution = 'Syntax Error'
    if inputSolution == 'Syntax Error'
      $('#solution-tex').empty().append(inputSolution)
      $('#solution_input_tex').val('')
      $('#solution_input_error').val(inputSolution)
    else
      latex = inputSolution.details.tex
      $('#solution_input_error').val('')
      $('#solution_input_tex').val(latex)
      $('#solution-tex').empty().append('$$' + latex + '$$')
      solutionTex = document.getElementById('solution-tex')
      $('#submit-solution').show()
      renderMathInElement solutionTex,
        delimiters: [
          {
            left: '$$'
            right: '$$'
            display: true
          }
          {
            left: '$'
            right: '$'
            display: false
          }
          {
            left: '\\('
            right: '\\)'
            display: false
          }
          {
            left: '\\['
            right: '\\]'
            display: true
          }
        ]
        throwOnError: false
    $('#solution-box').show()
    return

  $(document).on 'keyup', '[id^="tex-area-question-"]', ->
    $.ajax Routes.render_question_parameters_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        text: $(this).val()
        id: $(this).data('id')
      }
    return
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'keyup', '#question-basics-edit'
  $(document).off 'change', '#question-basics-edit :input'
  $(document).off 'click', '#question-basics-cancel'
  $(document).off 'change', '#questionSort :input'
  $(document).off 'keyup', '#question-solution-edit'
  $(document).off 'change', '#question-solution-edit :input'
  $(document).off 'change', '.solutionType'
  $(document).off 'change', '.rowCount'
  $(document).off 'change', '.columnCount'
  $(document).off 'keyup', '[id^="question_solution_content"]'
  $(document).off 'click', '#interpretExpression'
  $(document).off 'keyup', '[id^="tex-area-question-"]'
  return
