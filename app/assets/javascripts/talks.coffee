# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

@trixTalkPreview = (trixElement) ->
  trixElement.addEventListener 'trix-initialize', ->
    content = this.dataset.content
    editor = this.editor
    editor.setSelectedRange([0,65535])
    editor.deleteInDirection("forward")
    editor.insertHTML(content)
    document.activeElement.blur()
    trixElement.addEventListener 'trix-change', ->
      $('#talk-basics-warning').show()
      $('#talk-details-preview').html($('#talk-details-trix').html())
      chapterDetails = document.getElementById('talk-details-preview')
      renderMathInElement chapterDetails,
        delimiters: [
          {
            left: '$$'
            right: '$$'
            display: true
          }
          {
            left: '$'
            right: '$'
            display: false
          }
          {
            left: '\\('
            right: '\\)'
            display: false
          }
          {
            left: '\\['
            right: '\\]'
            display: true
          }
        ]
        throwOnError: false
      return
    return

$(document).on 'turbolinks:load', ->

  # if form is changed, display warning that there are unsaved changes
  $(document).on 'change', '#talk-form :input', ->
    $('#talk-basics-warning').show()
    return

  $(document).on 'click', '#cancel-talk-edit', ->
    location.reload(true)
    return

  trixElement = document.querySelector('#talk-details-trix')
  trixTalkPreview(trixElement) if trixElement?

  $(document).on 'click', '#new-talk-date-button', ->
    count = $(this).data('count')
    $('#talk-date-picker')
      .append('<div class="mt-2" id="talk_dates_'+count+'"><input type="date" name="talk[dates['+count+']]"><a class="fas fa-trash-alt clickable text-dark ml-2 remove-talk-date" data-count="'+count+'"></a></div>')
    $(this).data('count', count + 1)
    $('#talk-basics-warning').show()
    return

  $(document).on 'click', '.remove-talk-date', ->
    count = $(this).data('count')
    $('#talk_dates_' + count).remove()
    $('#talk-basics-warning').show()
    return

  $('#talk_speaker_ids').select2
    ajax:
      url: Routes.list_users_path()
      data: (params) ->
        { term: params.term }
      dataType: 'json'
      delay: 200
      processResults: (data) ->
        { results: data }
      cache: true
    language: $(this).data('locale')
    theme: 'bootstrap'
    minimumInputLength: 2
    placeholder: $(this).data('placeholder')
    allowClear: true

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'change', '#talk-form :input'
  $(document).off 'click', '#new-talk-date-button'
  $(document).off 'click', '.remove-talk-date'
  $(document).off 'click', '#cancel-talk-edit'
  $('#talk_speaker_ids').select2('destroy');
  return
