$(document).on 'turbolinks:load', ->
  clipboard = new Clipboard('.clipboard-btn')

  $(document).on 'click', '#removeUserManuscript', ->
    $('#userManuscriptMetadata').hide()
    $('#noUserManuscript').show()
    $(this).hide()
    $('#upload-userManuscript-hidden').val('')
    $('#submission_detach_user_manuscript').val('true')
    return

  return

# clean up for turbolinks
$(document).on 'turbolinks:before-cache', ->
  $(document).off '#removeUserManuscript'
  return