# render new talk form
$('#talk-modal-content').empty()
  .append('<%= j render partial: "talks/new",
                        locals: { lecture: @lecture,
                                  talk: @talk } %>').show()
$('#talkModal').modal('show')
$('[data-toggle="popover"]').popover()