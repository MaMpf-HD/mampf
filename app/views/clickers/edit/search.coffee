# render media results partial
searchResults = document.getElementById('media-search-results')
searchResults.innerHTML = '<%= j render partial: "media/catalog/search_results",
                                  locals: { media: @media,
                                            purpose: "clicker" } %>'

# run katex on search results
mediaResults = document.getElementById('media-search-results')
renderMathInElement mediaResults,
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

$('html, body').animate scrollTop: $('#media-search-results').offset().top - 20