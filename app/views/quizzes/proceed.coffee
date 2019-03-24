removeResidues = ->
  $('form').find('input:hidden').remove()
  $('form').children().unwrap()
  $('.send-it').prop 'disabled', true
  $('.send-it').addClass 'no_display'
  $('.click-it').prop 'disabled', true
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
  MathJax.Hub.Queue [
    'Typeset'
    MathJax.Hub
    '<%= @quiz_round.round_id %>'
  ]

displayNext = ->
  <% if @quiz_round.progress == -1 %>
  renderFinale('<%= j render partial: "quizzes/finale" %>')
  <% elsif @quiz_round.progress == 0 %>
  renderError('<%= j render partial: "quizzes/error" %>')
  <% else %>
  renderNext('<%= j render partial: "quizzes/quiz_round",
                           locals: { hidden: true } %>')
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
  $('#reduced-<%= @quiz_round.round_id_old %>').fadeIn 1000, reduceResults()
  return

displayWithoutAnswers = ->
  $('#footer-<%= @quiz_round.round_id_old %>').removeClass 'no_display'
  displayNext()

revealAnswers = (answers) ->
  $('#results-<%= @quiz_round.round_id_old %>').empty()
    .append answers
  MathJax.Hub.Queue [
    'Typeset'
    MathJax.Hub
    'body-<%= @quiz_round.round_id %>'
  ]

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
                                    old_id: @quiz_round.round_id_old } %>'
  revealAnswers(answers)
  success =  '<%= j render partial: "question_footer",
                           locals: { vertex: @quiz_round.vertex_old,
                                     input: @quiz_round.input } %>'
  revealSuccess(success)
  scrollDown()
  info = '<%= j render partial: "footer_info",
                        locals: { round_id: @quiz_round.round_id_old } %>'
  $('#accept_results').click ->
    acceptedResults(info, $previous_round)
    return
  <% end %>
  <% else %>
  displayNext()
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
    nextRound()
    return
  return
  <% end %>


removeResidues()
if detectLoop()
  removeLoop()
else
  nextRound()
