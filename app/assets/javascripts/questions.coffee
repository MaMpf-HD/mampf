# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# highlight 'Ungespeicherte Änderungen' if something is entered in question basics

extractSolution = ->
  content  = $('#solution-form').serializeArray().reduce(((obj, item) ->
    obj[item.name] = item.value
    obj
  ), {})
  type = content['question[solution_type]']
  if type == 'MampfExpression'
    statement = content['question[solution_content[0]]']
    nerd = nerdamer(statement)
    result =
      nerd: nerd
      tex: nerd.toTeX()
      statement: statement
    return result
  else if type == 'MampfMatrix'
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
    statement = 'matrix(' + matrix + ')'
    nerd = nerdamer(statement)
    result =
      nerd: nerd
      tex: nerd.toTeX().replace(/vmatrix/g, 'pmatrix')
      statement: statement
    return result
  else if type == 'MampfTuple'
    coeffs = content['question[solution_content[0]]']
    statement = 'vector(' + coeffs + ')'
    nerd = nerdamer(statement)
    texRaw = nerd.toTeX()
    tex = '(' + texRaw.substr(1, texRaw.length - 2) + ')'
    result =
      nerd: nerd
      tex: tex
      statement: statement
    return result
  else if type == 'MampfSet'
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
    statement = 'vector(' + set.join(',') + ')'
    nerd = nerdamer(statement)
    texRaw = nerd.toTeX()
    tex = '\\{' + texRaw.substr(1, texRaw.length - 2) + '\\}'
    result =
      nerd: nerd
      tex: tex
      statement: statement
    return result

compareToSolution = (expression) ->
  solutionString = $('#question_nerd').val()
  solutionNerd = nerdamer(solutionString)
  expressionNerd = nerdamer(expression)
  type = $('#question_solution_type').val()
  if type == 'MampfExpression'
    result = solutionNerd.expand().eq(expressionNerd.expand())
  else if type == 'MampfMatrix'
    rowCount = parseInt($('#question_row_count').val())
    columnCount = parseInt($('#question_column_count').val())
    if parseInt($('#matrixRowCount').data('count')) != rowCount ||
    parseInt($('#matrixColumnCount').data('count')) != columnCount
      result = false
    else
      result = true
      for i in [1..rowCount]
        for j in [1..columnCount]
          c1 = nerdamer('matget(' + solutionString + ',' + (i-1) + ',' + (j-1) + ')')
          c2 = nerdamer('matget(' + expression + ',' + (i-1) + ',' + (j-1) + ')')
          result = false unless c1.expand().eq(c2.expand())
  else if type == 'MampfTuple'
    size = parseInt(nerdamer('size(' + solutionString + ')'))
    if parseInt(nerdamer('size(' + expression + ')')) != size
      result = false
    else
      result = true
      for i in [1..size]
        c1 = nerdamer('vecget(' + solutionString + ',' + (i-1) + ')')
        c2 = nerdamer('vecget(' + expression + ',' + (i-1) + ')')
        result = false unless c1.expand().eq(c2.expand())
  else if type == 'MampfSet'
    size = parseInt(nerdamer('size(' + solutionString + ')'))
    console.log size
    console.log parseInt(nerdamer('size(' + expression + ')'))
    if size != parseInt(nerdamer('size(' + expression + ')'))
      result = false
    else
      result = true
      if size > 0
        for i in [1..size]
          c1 = nerdamer('vecget(' + solutionString + ',' + (i-1) + ')')
          found = false
          for j in [1..size]
            c2 = nerdamer('vecget(' + expression + ',' + (j-1) + ')')
            found = true if c1.expand().eq(c2.expand())
          result = false unless found
  $('#question_result').val(result)
  if result
    $('#quiz_question_crosses').val($('#quiz_question_crosses').data('answer'))
  else
    $('#quiz_question_crosses').val('')
  return

cleanSolutionBox = ->
  $('#solution-error').empty()
  $('#solution-box').hide()
  try
    expression = extractSolution()
  catch err
    expression = 'Syntax Error'
  if expression == 'Syntax Error'
    $('#solution_input_tex').val('')
    $('#solution_input_error').val(expression)
    $('#solution_content_nerd').val('')
    $('#question_result').val(false)
  else
    latex = expression.tex
    $('#solution_input_tex').val(latex)
    $('#question_quiz_solution_input').val('$' + latex + '$')
    $('#solution_input_error').val('')
    $('#solution_content_nerd').val(expression.statement)
    if $('#question_result').length > 0
      compareToSolution(expression.statement)
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
    try
      expression = extractSolution()
    catch err
      expression = 'Syntax Error'
    if expression == 'Syntax Error'
      $('#solution-tex').empty().append(expression)
      $('#solution_input_tex').val('')
      $('#solution_input_error').val(expression)
    else
      latex = expression.tex
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
  return
