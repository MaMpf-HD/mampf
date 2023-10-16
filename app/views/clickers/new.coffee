# render new course partial to the corresponding area,
# activate selectize and popovers
$('#new-clicker-area').empty()
  .append('<%= j render partial: "clickers/new",
                        locals: { clicker: @clicker } %>').show()
initBootstrapPopovers()

# hide all other buttons on admin index page
$('.admin-index-button').hide()

# restore page if creation of new course is cancelled
$('#cancel-new-clicker').on 'click', ->
  $('#new-clicker-area').empty().hide()
  $('#new-clicker-button').show()
  $('.admin-index-button').show()
  return