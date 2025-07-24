# The "target button" is either the "discard" button or the "edit" button
# what its purpose is is stored in this object with a mapping:
# answerId -> boolean
targetButtonIsDiscardButton = {}

# Set of answer ids that have a discard listener registered
# This is to avoid registering the same listener multiple times.
window.registeredDiscardListeners = new Set(); 

$(document).on 'turbo:load', ->

  $(document).on 'shown.bs.collapse', '[id^="collapse-answer-"]', ->
    # Answer is now shown to the user and can be edited
    answerId = $(this).data('id');
    registerDiscardListeners();
    targetButtonIsDiscardButton[answerId] = true;
    $target = $('#targets-answer-' + answerId)
    $target.empty().append($target.data('discard'))
      .removeClass('btn-primary').addClass('btn-secondary')

  $(document).on 'hidden.bs.collapse', '[id^="collapse-answer-"]', ->
    # Answer is now hidden from the user
    answerId = $(this).data('id')
    targetButtonIsDiscardButton[answerId] = false;
    $target = $('#targets-answer-' + answerId)
    $target.empty().append($target.data('edit'))
      .removeClass('btn-secondary').addClass('btn-primary')

  # Appearance of box
  $(document).on 'change', '[id^="answer-value-"]', ->
    id = $(this).data('id')
    isCorrectAnswer = $('#answer-true-' + id).is(':checked')

    # Set background color
    if isCorrectAnswer
      newClass = "<%= bgcolor(true) %>";
    else
      newClass = "<%= bgcolor(false) %>";
    $('#answer-header-' + id)
      .removeClass('bg-correct')
      .removeClass('bg-incorrect')
      .addClass(newClass)

    # Set ballot box
    answerBox = $('#answer-box-' + id)
    answerBox.empty()
    if isCorrectAnswer
      answerBox.append '<%= ballot_box(true) %>'
    else
      answerBox.append '<%= ballot_box(false) %>'

  # Cancel new answer creation
  $(document).on 'click', '#new-answer-cancel', ->
    $('#new-answer').show()
    $('#new-answer-field').empty()

$(document).on 'turbo:before-cache', ->
  $(document).off 'shown.bs.collapse', '[id^="collapse-answer-"]'
  $(document).off 'hidden.bs.collapse', '[id^="collapse-answer-"]'
  $(document).off 'change', '[id^="answer-value-"]'
  $(document).off 'click', '#new-answer-cancel'


registerDiscardListeners = () ->
  buttons = $('[id^=targets-answer-]');
  $.each(buttons, (i,btn) ->
    btn = $(btn);
    answerId = btn.attr('id').split('-')[2];

    # Don't register listeners multiple times
    if answerId in window.registeredDiscardListeners
      return;

    window.registeredDiscardListeners.add(answerId);
    $(this).on('click', (evt) =>
      isDiscardButton = targetButtonIsDiscardButton[answerId];
      if not isDiscardButton
        return;

      # On discard
      $.ajax Routes.cancel_edit_answer_path(answerId),
        type: 'GET'
        dataType: 'script'
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    );
  );
