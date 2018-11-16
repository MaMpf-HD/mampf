# disable all other input fields when a chapter is edited
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return
$('#lecture-preferences-form input').prop('disabled', true)

# render chapters form
$('#<%= dom_id(@chapter) %>').empty().removeClass('bg-mdb-color-lighten-2')
  .addClass('bg-yellow-lighten-5')
  .append('<%= j render partial: "chapters/form",
                        locals: { chapter: @chapter,
                                  lecture: @chapter.lecture } %>')
$('[data-toggle="popover"]').popover()