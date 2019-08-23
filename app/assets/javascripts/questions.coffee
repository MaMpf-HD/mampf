# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# highlight 'Ungespeicherte Änderungen' if something is entered in question basics

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
    content  = $('#solution-form').serializeArray().reduce(((obj, item) ->
      obj[item.name] = item.value
      obj
    ), {})
    columnCount =$('#matrixColumnCount').data('count')
    $('#matrixRowCount').data('count', rowCount)
    for i in [1..4]
      for j in [1..4]
        $entry = $('.matrixEntry[data-row="'+i+'"][data-column="'+j+'"]')
        if i <= rowCount && j <= columnCount
          $entry.show()
        else
          $entry.hide()
    $.ajax Routes.texify_solution_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        content: content
      }
    return


  $(document).on 'change', '.columnCount', ->
    columnCount = $(this).data('count')
    content  = $('#solution-form').serializeArray().reduce(((obj, item) ->
      obj[item.name] = item.value
      obj
    ), {})
    rowCount =$('#matrixRowCount').data('count')
    $('#matrixColumnCount').data('count', columnCount)
    for i in [1..4]
      for j in [1..4]
        $entry = $('.matrixEntry[data-row="'+i+'"][data-column="'+j+'"]')
        if i <= rowCount && j <= columnCount
          $entry.show()
        else
          $entry.hide()
    $.ajax Routes.texify_solution_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        content: content
      }
    return

  $(document).on 'keyup', '[id^="question_solution_content"]', ->
    $('#solution-error').empty()
    $('#solution-box').hide()
    try
      expression = nerdamer($('[id^="question_solution_content"]').val())
    catch err
      expression = 'Syntax Error'
    if expression == 'Syntax Error'
      $('#solution_input_tex').val('')
      $('#solution_input_error').val(expression)
    else
      latex = expression.toTeX()
      $('#solution_input_tex').val(latex)
      $('#solution_input_error').val('')
    return


  $(document).on 'click', '#interpretExpression', ->
    try
      expression = nerdamer($('[id^="question_solution_content"]').val())
    catch err
      expression = 'Syntax Error'
    if expression == 'Syntax Error'
      $('#solution-tex').empty().append(expression)
      $('#solution_input_tex').val('')
      $('#solution_input_error').val(expression)
    else
      latex = expression.toTeX()
      $('#solution_input_error').val('')
      $('#solution_input_tex').val(latex)
      $('#solution-tex').empty().append('$$' + latex + '$$')
      solutionTex = document.getElementById('solution-tex')
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
