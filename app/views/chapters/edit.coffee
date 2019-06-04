# disable all other input fields when a chapter is edited
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lectureAccordion .collapse').collapse('hide')
$('[data-toggle="collapse"]').addClass('disabled')
$('#new-announcement-button').addClass('disabled')

# render chapters form
$('#<%= dom_id(@chapter) %>').empty().removeClass('bg-mdb-color-lighten-2')
  .addClass('bg-yellow-lighten-5')
  .append('<%= j render partial: "chapters/form",
                        locals: { chapter: @chapter,
                                  lecture: @chapter.lecture } %>')
$('[data-toggle="popover"]').popover()