$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return
$('#<%= dom_id(@section) %>').empty().removeClass('bg-mdb-color-lighten-6')
  .addClass('bg-yellow-lighten-5')
  .append('<%= j render partial: "sections/form",
                        locals: { section: @section } %>')
$('#section-form .selectize').selectize({ plugins: ['remove_button'] })
