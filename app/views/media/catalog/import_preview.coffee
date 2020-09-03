# render media reults partial
searchResults = document.getElementById('media-search-results')
searchResults.innerHTML = '<%= j render partial: "media/catalog/search_results",
                                 locals: { media: @media,
                                           total: @total,
                                           purpose: @purpose } %>'

importTab = document.getElementById('importMedia')
selected = importTab.dataset.selected
if selected
  selected = JSON.parse(selected)
else
  selected = []

for id in selected
  $('#row-medium-' + id).addClass('bg-green-lighten-4')

if selected.length == 0
  $('#importMediaForm')
    .append '<%= j render partial: "shared/no_selection" %>'
else
  $('#importMediaForm')
    .append '<%= j render partial: "shared/import_form",
                          locals: { purpose: @purpose } %>'

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