# render user reults partial
searchResults = document.getElementById('user-search-results')
searchResults.innerHTML = '<%= j render partial: "users/search_results",
                                  locals: { users: @users } %>'