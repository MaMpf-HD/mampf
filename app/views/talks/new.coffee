# render new talk form
$('#talk-modal-content').empty()
  .append('<%= j render partial: "talks/new",
                        locals: { lecture: @lecture,
                                  talk: @talk } %>').show()
$('#talk_speaker_ids').select2
  ajax: {
    url: Routes.list_users_path()
    data: (params) ->
      {
        term: params.term
      }
    dataType: 'json'
    delay: 200
    processResults: (data) ->
      {
        results: data
      }
    cache: true
  }
  language: '<%= I18n.locale %>'
  theme: 'bootstrap'
  minimumInputLength: 2
  placeholder: '<%= t("basics.select") %>'
  allowClear: true

trixElement = document.querySelector('#talk-details-trix')
trixTalkPreview(trixElement)

$('#talkModal').modal('show')
$('[data-toggle="popover"]').popover()
