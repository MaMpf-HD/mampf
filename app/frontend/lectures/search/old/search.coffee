searchResults = document.getElementById('lecture-search-results-old')
searchResults.innerHTML = '<%= j render partial: "lectures/search/old/results",
                                 locals: { lectures: @lectures,
                                           pagy: @pagy } %>'
initBootstrapPopovers()