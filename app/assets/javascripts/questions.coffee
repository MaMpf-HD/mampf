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

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'keyup', '#question-basics-edit'
  $(document).off 'change', '#question-basics-edit :input'
  $(document).off 'click', '#question-basics-cancel'
  return
