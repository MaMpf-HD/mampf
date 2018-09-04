$('#media-search-results').empty()
  .append('<%= j render partial: "media/results",
                        locals: { media: @media } %>')
