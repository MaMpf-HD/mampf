# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# highlight 'Ungespeicherte Änderungen' if something is entered in remark basics

$(document).on 'turbo:load', ->

  $(document).on 'keyup', '#remark-basics-edit', ->
    $('#remark-basics-options').removeClass("no_display")
    $('#remark-basics-warning').removeClass("no_display")
    return

  $(document).on 'change', '#remark-basics-edit', ->
    $('#remark-basics-options').removeClass("no_display")
    $('#remark-basics-warning').removeClass("no_display")
    return

  # restore status quo if editing of remark basics is cancelled

  $(document).on 'click', '#remark-basics-cancel', ->
    $.ajax Routes.cancel_remark_basics_path($(this).data('id')),
      type: 'GET'
      dataType: 'script'
      error: (jqXHR, textStatus, errorThrown) ->
        console.log("AJAX Error: #{textStatus}")
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'keyup', '#remark-basics-edit'
  $(document).off 'change', '#remark-basics-edit'
  $(document).off 'click', '#remark-basics-cancel'
  return