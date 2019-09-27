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

  $(document).on 'mouseenter', '[id^="result-clickerizable-"]', ->
    mediumActions = document.getElementById('mediumActions')
    unless mediumActions.dataset.filled == 'true'
      $(this).addClass('bg-orange-lighten-4')
      $.ajax Routes.fill_medium_preview_path(),
         type: 'GET'
         dataType: 'script'
         data: {
           id: $(this).data('id')
           type: $(this).data('type')
         }
         error: (jqXHR, textStatus, errorThrown) ->
           console.log("AJAX Error: #{textStatus}")
    return

  $(document).on 'mouseleave', '[id^="result-clickerizable-"]', ->
    $(this).removeClass('bg-orange-lighten-4')
    return

  $(document).on 'click', '[id^="result-clickerizable-"]', ->
    mediumActions = document.getElementById('mediumActions')
    if $(this).hasClass('bg-green-lighten-4')
      $(this).removeClass('bg-green-lighten-4')
      $('#mediumPreview').empty()
      $('#mediumActions').empty()
      mediumActions.dataset.filled = 'false'
    else
      $('[id^="result-clickerizable-"]').removeClass('bg-green-lighten-4')
      $(this).removeClass('bg-orange-lighten-4').addClass('bg-green-lighten-4')
      $('[id^="result-clickerizable-"]').css('cursor','')
      $.ajax Routes.render_clickerizable_actions_path(),
        type: 'GET'
        dataType: 'script'
        data: {
          id: $(this).data('id')
          clicker: $('#clickerSearchForm').data('clicker')
        }
        error: (jqXHR, textStatus, errorThrown) ->
          console.log("AJAX Error: #{textStatus}")
    return


  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '.clickerAlternatives'
  $(document).off 'click', '#clickerQRButton'
  $(document).off 'click', '#toggleClickerResults'
  $(document).off 'click', '.associateClickerQuestion'
  $(document).off 'click', '#cancelSearch'
  $(document).off 'mouseenter', '[id^="result-clickerizable-"]'
  $(document).off 'mouseleave', '[id^="result-clickerizable-"]'
  $(document).off 'click', '[id^="result-clickerizable-"]'
  return