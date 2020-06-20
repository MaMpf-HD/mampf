$(document).on 'turbolinks:load', ->

  $(document).on 'keyup', '[id^="tex-area-"]', ->
    content = $(this).val()
    if $(this).data('parse')
      content = content.replace(/\\para{(\w+),(.*?)}/g, '{\\color{blue}{$1}}')
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

  $(document).on 'click', '.commentPreviewSwitch', ->
    $('#' + this.id.replace('switch','preview')).toggle()
    return


  $(document).on 'keyup', '.commentForm', ->
    content = sanitizeHtml($(this).val(),
      allowedTags: [
        'b',
        'em'
        'strong'
        'i'
        'br'
        'p'
        'code'
        'pre'
      ])
    preview = '#' + this.id + '-preview'
    $(preview).html(content)
    # run katex on preview
    previewBox = document.getElementById(this.id + '-preview')
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
  $(document).off 'keyup', '[id^="tex-area-"]'
  $(document).off 'keyup', '.commentForm'
  $(document).off 'click', '.commentPreviewSwitch'
  return
