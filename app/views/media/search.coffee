$('#media-search-results').empty()
  .append('<%= j render partial: "media/results",
                        locals: { media: @media } %>')
mediaResults = document.getElementById('media-search-results')
renderMathInElement(mediaResults, delimiters: [
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
  },
  throwOnError: false
])
