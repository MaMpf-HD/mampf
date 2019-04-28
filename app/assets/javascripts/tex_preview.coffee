$(document).on 'turbolinks:load', ->

  $(document).on 'change', '[id^="tex-area-"]', ->
    content = $(this).val()
    preview = '#' + this.id.replace('area','preview')
    $(preview).text content
    # run katex on preview
    previewBox = document.getElementById(this.id.replace('area','preview'))
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

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '[id^="tex-area-"]'
  return
