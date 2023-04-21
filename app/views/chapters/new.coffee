# render new chapter form
$('#chapter-modal-content').empty()
  .append('<%= j render partial: "chapters/new",
                        locals: { lecture: @lecture,
                                  chapter: @chapter} %>').show()
$('#chapterModal').modal('show')
$('[data-toggle="popover"]').popover()
