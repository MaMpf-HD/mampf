# render lecture results partial
searchResults = document.getElementById('lecture-search-results')
searchResults.innerHTML = '<%= j render partial: "lectures/search/results",
                                 locals: { lectures: @lectures,
                                           total: @total } %>'
$('[data-bs-toggle="popover"]').popover()