$(document).on 'change', '[id^="tex-area-"]', ->
  content = $(this).val()
  preview = '#' + this.id.replace('area','preview')
  $(preview).text content
  MathJax.Hub.Queue [
    'Typeset'
    MathJax.Hub
    this.id.replace('area','preview')
  ]
  return
