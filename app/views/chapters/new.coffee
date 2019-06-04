# disable all other input fields when a new chapter is being created
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lectureAccordion .collapse').collapse('hide')
$('[data-toggle="collapse"]').addClass('disabled')
$('#new-announcement-button').addClass('disabled')


# render new chapter form
$('#new-chapter-area').empty()
  .append('<%= j render partial: "chapters/new",
                        locals: { lecture: @lecture,
                                  chapter: @chapter} %>').show()
$('[data-toggle="popover"]').popover()
