$(document).on 'turbolinks:load', ->
  clipboard = new Clipboard('.clipboard-btn')

  restoreClipboardButton = ->
    $('#token-clipboard-popup').removeClass('show')

  $(document).on 'click', '#removeUserManuscript', ->
    $('#userManuscriptMetadata').hide()
    $('#noUserManuscript').show()
    $(this).hide()
    $('#upload-userManuscript-hidden').val('')
    $('#submission_detach_user_manuscript').val('true')
    return

  $(document).on 'click', '#clipboard-button', ->
    $('#token-clipboard-popup').addClass('show')
    setTimeout(restoreClipboardButton, 1500)
    return

  return

# clean up for turbolinks
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'click', '#removeUserManuscript'
  $(document).off 'click', '#clipboard-button'
  return