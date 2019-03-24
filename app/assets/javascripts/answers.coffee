# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# change button 'Bearbeiten' to 'verwerfen' after answer body is revealed

$(document).on 'shown.bs.collapse', '[id^="collapse-answer-"]', ->
  $('#targets-answer-' + $(this).data('id')).empty()
    .append('verwerfen').removeClass('btn-primary').addClass('btn-secondary')

# change button 'verwerfen' back to 'Ziele ändern' and rerender answer body
# and header after answer body is hidden

$(document).on 'hidden.bs.collapse', '[id^="collapse-answer-"]', ->
  $.ajax Routes.update_answer_body_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      answer_id: $(this).data('id')
      input: $('#tex-area-answer-' + $(this).data('id')).val()
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# change correctness box for answer if radio button is clicked

$(document).on 'change', '[id^="answer-value-"]', ->
  $.ajax Routes.update_answer_box_path(),
    type: 'GET'
    dataType: 'script'
    data: {
      answer_id: $(this).data('id')
      value: $('#answer-true-' + $(this).data('id')).is(':checked')
    }
    error: (jqXHR, textStatus, errorThrown) ->
      console.log("AJAX Error: #{textStatus}")

# remove card for new answer if creation of new answer is cancelled

$(document).on 'click', '#new-answer-cancel', ->
  $('#new-answer').show()
  $('#new-answer-field').empty()
