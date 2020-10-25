$('#newTutorialButton').hide()
$('#tutorialListHeader').show()
  .after('<%= j render partial: "tutorials/form",
                       locals: { tutorial: @tutorial } %>')

$('#tutorial_tutor_ids_').select2
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