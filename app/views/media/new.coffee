# disable all other input fields when a new medium is created
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lectureAccordion .collapse').collapse('hide')
$('[data-toggle="collapse"]').addClass('disabled')

# render new medium form
$('#new-medium-area').empty()
  .append('<%= j render partial: "media/new",
                        locals: { medium: @medium } %>').show()

 # activate popovers
$('[data-toggle="popover"]').popover()
