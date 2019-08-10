$(document).on 'turbolinks:load', ->
  $(document).on 'change', '.clickerAlternatives', ->
    alternatives = $(this).data('alternatives')
    clickerId = $(this).data('clicker')
    $.ajax Routes.set_clicker_alternatives_path(clickerId),
      type: 'POST'
      dataType: 'script'
      data: {
        alternatives: alternatives
      }
    return
  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '.clickerAlternatives'
  return