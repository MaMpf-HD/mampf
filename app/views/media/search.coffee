$('#media-search-results').empty()
  .append('<%= j render partial: "media/results",
                        locals: { media: @media } %>')
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'media-search-results'
]
