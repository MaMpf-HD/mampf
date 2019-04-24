# disable all other input fields when a section is edited
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-preferences-form input').prop('disabled', true)
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return

# render edit section form
$('#<%= dom_id(@section) %>').empty().removeClass('bg-mdb-color-lighten-6')
  .addClass('bg-yellow-lighten-5')
  .append('<%= j render partial: "sections/form",
                        locals: { section: @section } %>')

 # activate popovers and selectize
$('#section-form .selectize').selectize({ plugins: ['remove_button', 'drag_drop'] })
$('[data-toggle="popover"]').popover()
# bugfix for selectize (which sometimes renders the prompt with a zero width)
$('input[id$="-selectized"]').css('width', '100%')