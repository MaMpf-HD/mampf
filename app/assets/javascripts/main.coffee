# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # *ugly* fix for the following bootstrap bug:
  # after clicking the link to the blog which opens a new tab
  # the nav link remains in hovered state which cannot be
  # unhovered by moving the mouse away
  $('#blog').on 'click', ->
    $(this).clone().insertAfter($(this))
    $(this).remove()
    return

  return