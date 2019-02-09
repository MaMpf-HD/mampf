# disable all other input fields when a new section is created
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lecture-preferences-form input').prop('disabled', true)
$('#lecture-form input').prop('disabled', true)
$('#lecture-form .selectized').each ->
  this.selectize.disable()
  return

# render new section form
$('#new-section-area-<%= @chapter.id %>').empty()
  .append('<%= j render partial: "sections/new",
                        locals: { section: @section,
                                  chapter: @chapter } %>').show()

 # activate popovers
$('[data-toggle="popover"]').popover()
