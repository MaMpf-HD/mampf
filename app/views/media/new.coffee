# render new medium modal
$('#medium-modal-content').empty()
  .append('<%= j render partial: "media/new",
                        locals: { medium: @medium } %>').show()
$('#mediumModal').modal('show')
initBootstrapPopovers()
