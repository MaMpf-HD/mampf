# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@trixTalkPreview = (trixElement) ->
  content = trixElement.dataset.content
  preview = trixElement.dataset.preview
  editor = trixElement.editor
  editor.setSelectedRange([0,65535])
  editor.deleteInDirection("forward")
  editor.insertHTML(content)
  document.activeElement.blur()
  trixElement.addEventListener 'trix-change', ->
    $('#talk-basics-warning').show()
    $('#'+preview).html($(this).html())
    previewBox = document.getElementById(preview)
    renderMathInElement previewBox,
      delimiters: [
        {
          left: '$$'
          right: '$$'
          display: true
        }
        {
          left: '$'
          right: '$'
          display: false
        }
        {
          left: '\\('
          right: '\\)'
          display: false
        }
        {
          left: '\\['
          right: '\\]'
          display: true
        }
      ]
      throwOnError: false
    return

$(document).on 'turbolinks:load', ->

  # if form is changed, display warning that there are unsaved changes
  $(document).on 'change', '#talk-form :input', ->
    $('#talk-basics-warning').show()
    return

  $(document).on 'click', '#cancel-talk-edit', ->
    location.reload(true)
    return

  $(document).on 'click', '#cancel-talk-assemble', ->
    location.reload(true)
    return

  trixDetailsElement = document.querySelector('#talk-details-trix')
  trixTalkPreview(trixDetailsElement) if trixDetailsElement?

  trixDescriptionElement = document.querySelector('#talk-description-trix')
  trixTalkPreview(trixDescriptionElement) if trixDescriptionElement?

  $(document).on 'click', '#new-talk-date-button', ->
    count = $(this).data('count')
    $('#talk-date-picker')
      .append('<div class="mt-2" id="talk_dates_'+count+'"><input type="date" name="talk[dates['+count+']]"><a class="fas fa-trash-alt clickable text-dark ml-2 remove-talk-date" data-count="'+count+'"></a></div>')
    $(this).data('count', count + 1)
    $('#talk-basics-warning').show()
    return

  $(document).on 'click', '.remove-talk-date', ->
    count = $(this).data('count')
    $('#talk_dates_' + count).remove()
    $('#talk-basics-warning').show()
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#talk-form :input'
  $(document).off 'click', '#new-talk-date-button'
  $(document).off 'click', '.remove-talk-date'
  $(document).off 'click', '#cancel-talk-edit'
  return
