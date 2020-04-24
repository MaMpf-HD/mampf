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

  $(document).on 'click', '.subscriptionSwitch', ->
    $.ajax Routes.toggle_thread_subscription_path(),
      type: 'POST'
      dataType: 'script'
      data: {
        id: $(this).data('id')
        subscribe: $(this).is(':checked')
      }


  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '.subscriptionSwitch'
  return