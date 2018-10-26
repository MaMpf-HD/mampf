$('#chapter-modal-content').empty()
  .append('<%= j render partial: "chapters/form",
                        locals: { chapter: @chapter,
                        		  lecture: @chapter.lecture } %>')
$('#chapterModal').modal('show')