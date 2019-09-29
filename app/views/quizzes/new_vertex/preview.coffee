# render media reults partial
searchResults = document.getElementById('media-search-results')
searchResults.innerHTML = '<%= j render partial: "media/catalog/search_results",
                                 locals: { media: @media,
                                           purpose: "quiz" } %>'

importTab = document.getElementById('import-vertex-tab')
selected = importTab.dataset.selected
if selected
  selected = JSON.parse(selected)
else
  selected = []

for id in selected
  $('#result-quizzable-' + id).addClass('bg-green-lighten-4')

if selected.length == 0
  $('#importVertexForm')
    .append '<%= j render partial: "quizzes/new_vertex/no_selection" %>'
else
  $('#importVertexForm')
    .append '<%= j render partial: "quizzes/new_vertex/form" %>'

$('#selectionCounter').empty().append('(' + selected.length + ')')

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