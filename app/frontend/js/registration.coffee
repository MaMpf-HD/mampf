$(document).on 'turbo:load', ->

  # make sure user can only register if DSVGO checkbox has been checked
  $(document).on 'click', '#register-user', (evt) ->
    if $('#dsgvo-consent').prop('checked') == false
      alert $('#dsgvo-consent').data('noconsent')
      evt.preventDefault()
    return

  return

$(document).on 'turbo:before-cache', ->
  $(document).off 'click', '#register-user'
  return