removeResidues = ->
  $('main form').find('input:hidden').remove()
  $('main form').children().unwrap()
  $('.send-it').prop 'disabled', true
  $('.send-it').addClass 'no_display'
  $('.click-it').prop 'disabled', true
  $('.type-it').prop 'disabled', true
  $('.type-it').addClass 'no_display'
  $('.type-it-label').remove()
  $('.remark-infotainment-text').remove()
  $('.remark-infotainment-icons').show()
  return

detectLoop = ->
  <% unless @quiz_round.progress.nil? %>
  $('[id^="round<%= @quiz_round.progress %>-"]').length == 1
  <% end %>

changeBackground = ->
  $previous_round = $("#<%= @quiz_round.round_id_old %>").find(".card")
                      .removeClass "bg-question"
  $previous_round.addClass '<%= @quiz_round.background %>'
  return $previous_round

renderFinale = (finale) ->
  $('#<%= quiz_id%>').append finale
  $('[data-toggle="popover"]').popover()
  $('#finale').delay(1000).slideDown 'slow'
  $('html, body').delay(500)
    .animate { scrollTop: document.body.scrollHeight }, 2000
  return

renderError = (error) ->
  $('#<%= quiz_id%>').append error
  return

renderNext = (round) ->
  $('#<%= quiz_id%>').append round
  $('#<%= @quiz_round.round_id %>').delay(500).slideDown 'slow', ->
    $(this).removeClass 'no_display'
    return
  $('html, body').delay(500)
    .animate { scrollTop: document.body.scrollHeight }, 2000
  quizRound = document.getElementById('<%= @quiz_round.round_id %>')
  renderMathInElement quizRound,
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
  return

displayNext = ->
  <% if @quiz_round.progress == -1 %>
  renderFinale('<%= j render partial: "quizzes/finale",
                             locals: { xkcd: XKCD.img,
                                       certificate:
                                         @quiz_round.certificate } %>')
  <% elsif @quiz_round.progress == 0 %>
  renderError('<%= j render partial: "quizzes/error" %>')
  <% else %>
  renderNext('<%= j render partial: "quizzes/quiz_round",
                           locals: { hidden: true } %>')
  $('[data-toggle="popover"]').popover()
  <% end %>
  return

reduceResults = ->
  displayNext()
  $('#toggle_results-<%= @quiz_round.round_id_old %>')
    .data('status', 'reduced')
    .data 'color', '<%= @quiz_round.background %>'
  return

acceptedResults = (info, $previous_round) ->
  $(this).remove()
  $previous_round.removeClass('bg-correct').removeClass('bg-incorrect')
    .addClass 'bg-question'
  $('#results-<%= @quiz_round.round_id_old %>').hide 600
  $('#footer-<%= @quiz_round.round_id_old %>').empty()
    .append info
  $('#correctness-<%= @quiz_round.round_id_old %>')
    .addClass('<%= @quiz_round.badge %>')
    .append '<%= @quiz_round.statement %>'
  $('#reduced-<%= @quiz_round.round_id_old %>')
    .append('<%= j render partial: "quizzes/answers_reduced",
                          locals: { answers: @quiz_round.answers_old,
                                    result: @quiz_round.result } %>')
  oldAnswers = document.getElementById('reduced-<%= @quiz_round.round_id_old %>')
  renderMathInElement oldAnswers,
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
  $('#reduced-<%= @quiz_round.round_id_old %>')
    .fadeIn 1000, reduceResults()
  return

displayWithoutAnswers = ->
  $('#footer-<%= @quiz_round.round_id_old %>').removeClass 'no_display'
  <% if @quiz_round.solution_input.present? %>
  $('#results-<%= @quiz_round.round_id_old %>').empty()
    .append('<%= j render partial: "quizzes/take/old_solution_input",
                          locals: { solution_input: @quiz_round.solution_input } %>')
  oldInput = document.getElementById('results-<%= @quiz_round.round_id_old %>')
  renderMathInElement oldInput,
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
  <% end %>
  displayNext()
  return

revealAnswers = (answers) ->
  $('#results-<%= @quiz_round.round_id_old %>').empty()
    .append answers
  quizRoundBody = document.getElementById('results-<%= @quiz_round.round_id_old %>')
  renderMathInElement quizRoundBody,
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
  return

revealSuccess = (success) ->
  $('#footer-<%= @quiz_round.round_id_old %>').removeClass('no_display')
    .empty().append success

scrollDown = ->
  $('html, body').delay(500)
    .animate { scrollTop: document.body.scrollHeight }, 2000

nextRound = ->
  <% if @quiz_round.is_question %>
  $previous_round = changeBackground()
  <% if @quiz_round.hide_solution %>
  displayWithoutAnswers()
  <% else %>
  answers = '<%= j render partial: "quizzes/question_closed",
                          locals: { progress: @quiz_round.progress_old,
                                    vertex: @quiz_round.vertex_old,
                                    input: @quiz_round.input,
                                    old_id: @quiz_round.round_id_old,
                                    answers: @quiz_round.answers_old,
                                    solution_input: @quiz_round.solution_input,
                                    result: @quiz_round.result } %>'
  revealAnswers(answers)
  success =  '<%= j render partial: "question_footer",
                           locals: { vertex: @quiz_round.vertex_old,
                                     input: @quiz_round.input } %>'
  revealSuccess(success)
  scrollDown()
  info = '<%= j render partial: "footer_info",
                        locals: { round_id: @quiz_round.round_id_old,
                                  question_id: @quiz_round.question_id } %>'
  $('#accept_results').click ->
    acceptedResults(info, $previous_round)
    return
  <% end %>
  <% else %>
  displayNext()
  <% end %>
  return

presentResultsToLoop = ->
  <% if @quiz_round.is_question %>
  $previous_round = changeBackground()
  <% if @quiz_round.hide_solution %>
  displayWithoutAnswers()
  <% else %>
  answers = '<%= j render partial: "quizzes/question_closed",
                          locals: { progress: @quiz_round.progress_old,
                                    vertex: @quiz_round.vertex_old,
                                    input: @quiz_round.input,
                                    old_id: @quiz_round.round_id_old,
                                    answers: @quiz_round.answers_old,
                                    solution_input: @quiz_round.solution_input,
                                    result: @quiz_round.result } %>'
  revealAnswers(answers)
  success =  '<%= j render partial: "question_footer",
                           locals: { vertex: @quiz_round.vertex_old,
                                     input: @quiz_round.input } %>'
  revealSuccess(success)
  scrollDown()
  info = '<%= j render partial: "footer_info",
                        locals: { round_id: @quiz_round.round_id_old,
                                  question_id: @quiz_round.question_id } %>'
  $('#accept_results').click ->
    removeLoop()
    return
  <% end %>
  <% else %>
  removeLoop()
  <% end %>
  return



removeLoop = ->
  <% unless @quiz_round.progress.nil? %>
  $current = $('[id^="round<%= @quiz_round.progress %>-"]')
  $neighbours = $('[id^="round<%= @quiz_round.progress %>-"]').nextAll()
  $all = $current.add($neighbours)
  $all.wrapAll '<div id="loop"></div>'
  $('#loop').fadeOut 2000, ->
    $(this).remove()
    displayNext()
    return
  return
  <% end %>


removeResidues()
if detectLoop()
  presentResultsToLoop()
else
  nextRound()
