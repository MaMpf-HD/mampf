$('#media-search-results').empty()
$('#importedMediaTable').empty()
  .append('<%= j render partial: "lectures/import/imported_media",
                        locals: { media: @lecture.imported_media,
                                  lecture: @lecture,
                                  inspection: false } %>')
$('#importedMediaArea').hide()
$('#import-media-button').show()
$('#importedMediaCount').empty().append('<%= "(#{@lecture.imported_media.size})" %>')
importTab = document.getElementById('importMedia')
importTab.dataset.selected = []