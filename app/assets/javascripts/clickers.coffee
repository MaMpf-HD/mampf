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

  $(document).on 'click', '#clickerQRButton', ->
    console.log 'Hi'
    if $(this).data('showqr')
      $('#clickerQRCode').hide()
      $(this).data('showqr', false)
      $(this).html($(this).data('showbutton'))
    else
      $('#clickerQRCode').show()
      $(this).data('showqr', true)
      $(this).html($(this).data('hidebutton'))
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '.clickerAlternatives'
  return