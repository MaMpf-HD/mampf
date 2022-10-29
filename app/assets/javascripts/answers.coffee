# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# change button 'Bearbeiten' to 'verwerfen' after answer body is revealed

$(document).on 'turbolinks:load', ->

  $(document).on 'shown.bs.collapse', '[id^="collapse-answer-"]', ->
    $target = $('#targets-answer-' + $(this).data('id'))
    $target.empty().append($target.data('discard'))
      .removeClass('btn-primary').addClass('btn-secondary')
    return

  # submit form to database after answer body is hidden and restore
  # buttons after after answer body is hidden

  $(document).on 'hidden.bs.collapse', '[id^="collapse-answer-"]', ->
    answerId = $(this).data('id')
    text = $('#tex-area-answer-' + answerId).val()
    value = $('#answer-true-' + answerId).is(':checked')
    explanation = $('#tex-area-explanation-' + answerId).val()
    $target = $('#targets-answer-' + answerId)
    $target.empty()
      .append($target.data('edit'))
      .removeClass('btn-secondary').addClass 'btn-primary'
    $.ajax Routes.answer_path(answerId),
      type: 'PATCH'
      dataType: 'script'
      data: {
        answer: {
          text: text
          value: value
          explanation: explanation
        }
      }
    return

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
    return

  # remove card for new answer if creation of new answer is cancelled

  $(document).on 'click', '#new-answer-cancel', ->
    $('#new-answer').show()
    $('#new-answer-field').empty()
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'shown.bs.collapse', '[id^="collapse-answer-"]'
  $(document).off 'hidden.bs.collapse', '[id^="collapse-answer-"]'
  $(document).off 'change', '[id^="answer-value-"]'
  $(document).off 'click', '#new-answer-cancel'
  return

