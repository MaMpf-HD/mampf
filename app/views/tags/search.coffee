# render media reults partial
searchResults = document.getElementById('tag-search-results')
searchResults.innerHTML = '<%= j render partial: "tags/results",
                                  locals: { tags: @tags } %>'

# run katex on search results
tagResults = document.getElementById('tag-search-results')
renderMathInElement tagResults,
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
