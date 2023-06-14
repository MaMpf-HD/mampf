# render course results partial
searchResults = document.getElementById('course-search-results')
searchResults.innerHTML = '<%= j render partial: "courses/search/results",
                                 locals: { courses: @courses,
                                           total: @total } %>'
$('[data-bs-toggle="popover"]').popover()