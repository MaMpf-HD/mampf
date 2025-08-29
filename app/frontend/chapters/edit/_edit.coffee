# disable all other input fields when a chapter is edited


$('#chapter-modal-content').empty()
  .append('<%= j render partial: "chapters/form",
                        locals: { chapter: @chapter,
                                  lecture: @chapter.lecture } %>')
$('#chapterModalLabel').empty()
  .append('<%= t("admin.chapter.edit",
                 chapter: @chapter.to_label) %>')
initBootstrapPopovers()
$('#chapterModal').modal('show')