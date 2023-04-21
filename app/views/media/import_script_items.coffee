# rerender toc box, scroll item into view and colorize it properly
$('#toc-area').empty()
  .append('<%= j render partial: "media/toc",
                        locals: { medium: @medium } %>')
tocArea = document.getElementById('toc-area')
renderMathInElement tocArea,
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

# activate export toc button
$('#export-toc').show()

# clean up action box
$('#action-placeholder').empty()
$('#action-container').empty()
