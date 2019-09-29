# render media reults partial
searchResults = document.getElementById('media-search-results')
searchResults.innerHTML = '<%= j render partial: "media/catalog/search_results",
                                  locals: { media: @media,
                                            total: @total,
                                            purpose: @purpose } %>'

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

tagIdsSelect = document.getElementById('medium_tag_ids')
if tagIdsSelect and tagIdsSelect.dataset.filled == 'false'
  $.ajax Routes.fill_tag_select_path(),
    type: 'GET'
    dataType: 'json'
    success: (result) ->
      for option in result
        new_option = document.createElement('option')
        new_option.value = option.value
        new_option.text = option.text
        tagIdsSelect.add(new_option, null)
        tagIdsSelect.dataset.filled = 'true'
      $(tagIdsSelect).selectize({ plugins: ['remove_button'] })
      return
  return
