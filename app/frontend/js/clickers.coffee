$(document).on 'turbolinks:load', ->
  $(document).on 'change', '.clickerAlternatives', ->
    alternatives = $(this).data('alternatives')
    clickerId = $(this).data('clicker')
    $.ajax Routes.set_clicker_alternatives_path(clickerId),
      type: 'POST'
      dataType: 'script'
      data: {
        alternatives: alternatives
        code:  $(this).data('code')
      }
    return

  $(document).on 'click', '#clickerQRButton', ->
    if $(this).data('showqr')
      $('#clickerQRCode').hide()
      $(this).data('showqr', false)
      $(this).html($(this).data('showbutton'))
    else
      $('#clickerQRCode').show()
      $(this).data('showqr', true)
      $(this).html($(this).data('hidebutton'))
    return

  $(document).on 'click', '#toggleClickerResults', ->
    if $(this).data('show')
      $('#lastPollResults').hide()
      $(this).data('show', false)
      $(this).html($(this).data('showbutton'))
    else
      $('#lastPollResults').show()
      $(this).data('show', true)
      $(this).html($(this).data('hidebutton'))
    return

  $(document).on 'click', '.associateClickerQuestion', ->
    $('#clickerSearchForm').show()
    $('#cancelSearch').data('change', $(this).data('change'))
    $('#clickerAlternativeSelection').hide()
    $('#clickerAssociatedQuestion').hide()
    $('#openClickerButton').hide()
    return

  $(document).on 'click', '#cancelSearch', ->
    if $(this).data('purpose') == 'clicker'
      $('#clickerSearchForm').hide()
      $('#openClickerButton').show()
      if $(this).data('change')
        $('#clickerAssociatedQuestion').show()
      else
        $('#clickerAlternativeSelection').show()
    else if $(this).data('purpose') == 'import'
      $('#importedMediaArea').hide()
      $('#import-media-button').show()
    return

  $(document).on 'click', '#clickerHideEditorLink', ->
    if $(this).data('showlink')
      $(this).data('showlink', false)
      $(this).html($(this).data('showbutton'))
      $('#clickerEditorLink').hide()
      $('#clickerNoLink').show()
    else
      $(this).data('showlink', true)
      $(this).html($(this).data('hidebutton'))
      $('#clickerEditorLink').show()
      $('#clickerNoLink').hide()
    return


  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '.clickerAlternatives'
  $(document).off 'click', '#clickerQRButton'
  $(document).off 'click', '#toggleClickerResults'
  $(document).off 'click', '.associateClickerQuestion'
  $(document).off 'click', '#cancelSearch'
  $(document).off 'click', '#clickerHideEditorLink'
  return