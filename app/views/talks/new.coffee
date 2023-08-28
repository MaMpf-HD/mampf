# render new talk form
$('#talk-modal-content').empty()
  .append('<%= j render partial: "talks/new",
                        locals: { lecture: @lecture,
                                  talk: @talk } %>').show()
fillOptionsByAjax($('#talk_speaker_ids'))

trixElement = document.querySelector('#talk-details-trix')
trixTalkPreview(trixElement)

$('#talkModal').modal('show')
initBootstrapPopovers()
