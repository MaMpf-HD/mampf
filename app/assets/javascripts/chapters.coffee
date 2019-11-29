# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  # if form is changed, display warning that there are unsaved changes
  $(document).on 'change', '#chapter-form :input', ->
    $('#chapter-basics-warning').show()
    return

  $(document).on 'click', '#cancel-chapter-edit', ->
    location.reload()
    return

  $(document).on 'trix-change', '#chapter-details-trix', ->
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


  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#chapter-form :input'
  $(document).off 'click', '#cancel-chapter-edit'
  return
