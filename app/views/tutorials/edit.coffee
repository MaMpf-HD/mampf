$('.tutorialRow[data-id="<%= @tutorial.id %>"')
  .replaceWith('<%= j render partial: "tutorials/form",
                      locals: { tutorial: @tutorial } %>')

$('#tutorial_tutor_id').select2
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
  escapeMarkup: (markup) -> markup
  minimumInputLength: 2
  templateResult: (item) -> item.name
  templateSelection: (item) -> item.name
