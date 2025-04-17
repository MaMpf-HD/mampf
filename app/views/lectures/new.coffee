# render new lecture partial to the corresponding area,
# activate selectize and popovers
$('#new-lecture-area').empty()
  .append('<%= j render partial: "lectures/new",
                        locals: { lecture: @lecture,
                                  from: @from,
                                  modal: @from == "course" } %>').show()
fillOptionsByAjax($('#new-lecture-area .selectize'))
initBootstrapPopovers()

# hide all other buttons on admin index page
$('.admin-index-button').hide()

# show the modal if the new action was triggered from course edit page
<% if @from == 'course' %>
$('#newLectureModal').modal('show')
<% end %>
