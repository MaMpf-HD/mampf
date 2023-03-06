# render new section form
$('#section-modal-content').empty()
  .append('<%= j render partial: "sections/new",
                        locals: { section: @section,
                                  chapter: @chapter } %>').show()

$('#sectionModal').modal('show')
 # activate popovers
$('[data-bs-toggle="popover"]').popover()
