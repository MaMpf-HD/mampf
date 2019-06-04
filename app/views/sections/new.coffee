# disable all other input fields when a new section is created
$('.fa-edit').hide()
$('.new-in-lecture').hide()
$('#lectureAccordion .collapse').collapse('hide')
$('[data-toggle="collapse"]').addClass('disabled')
$('#new-announcement-button').addClass('disabled')

# render new section form
$('#new-section-area-<%= @chapter.id %>').empty()
  .append('<%= j render partial: "sections/new",
                        locals: { section: @section,
                                  chapter: @chapter } %>').show()

 # activate popovers
$('[data-toggle="popover"]').popover()
