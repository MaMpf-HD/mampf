$(document).on 'turbo:load', ->

  $(document).on 'click', '#removeUserManuscript', ->
    $('#userManuscriptMetadata').hide()
    $('#noUserManuscript').show()
    $(this).hide()
    $('#upload-userManuscript-hidden').val('')
    $('#submission_detach_user_manuscript').val('true')
    return

  return

$(document).on 'turbo:before-cache', ->
  $(document).off 'click', '#removeUserManuscript'
  return