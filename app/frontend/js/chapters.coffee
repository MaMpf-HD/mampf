$(document).on 'turbo:load', ->

  # if form is changed, display warning that there are unsaved changes
  $(document).on 'change', '#chapter-form :input', ->
    $('#chapter-basics-warning').show()
    return

  $(document).on 'click', '#cancel-chapter-edit', ->
    location.reload(true)
    return

  trixElement = document.querySelector('#chapter-details-trix')
  if trixElement?
    content = trixElement.dataset.content
    editor = trixElement.editor
    if !editor
      return
    editor.setSelectedRange([0,65535])
    editor.deleteInDirection("forward")
    editor.insertHTML(content)
    document.activeElement.blur()
    trixElement.addEventListener 'trix-change', ->
      $('#chapter-basics-warning').show()
      $('#chapter-details-preview').html($('#chapter-details-trix').html())
      chapterDetails = document.getElementById('chapter-details-preview')
      renderMathInElement chapterDetails,
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


  return

$(document).on 'turbo:before-cache', ->
  $(document).off 'change', '#chapter-form :input'
  $(document).off 'click', '#cancel-chapter-edit'
  return
