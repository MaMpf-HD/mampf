# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('[id^="section-form-"] :input').on 'change', ->
    sectionId = this.dataset.id
    chapterId = this.dataset.chapter
    $('#section-basics-warning-' + sectionId).show()
    $('#details-section-' + sectionId).text('verwerfen')
    $('#details-section-' + sectionId).on 'click', (event) ->
      event.preventDefault()
      window.location.href = Routes.edit_chapter_path(chapterId)
      return
    tags = document.getElementById('section_tag_ids_' + sectionId).selectize.getValue()
    $.ajax Routes.list_section_tags_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: sectionId
        tags: JSON.stringify(tags)
      }
    return

  $('[id^="collapse-section-"]').on 'hidden.bs.collapse', ->
    sectionId = this.dataset.section
    $('#details-section-' + sectionId).text('Bearbeiten')
    $('#card-section-' + sectionId).addClass('bg-mdb-color-lighten-6')
    return

  $('[id^="collapse-section-"]').on 'show.bs.collapse', ->
    $('#cancel-new-section').trigger 'click'
    sectionId = this.dataset.section
    $('#card-section-' + sectionId).removeClass('bg-mdb-color-lighten-6')
    $('#details-section-' + sectionId).text('Zuklappen')
    return

  $('[id^="section-tag-links-"]').on 'click', ->
    sectionId = this.dataset.id
    if $('#section-tag-list-' + sectionId).data('show') == 0
      $('#section-tag-list-' + sectionId).data('show', 1).show()
      $(this).text('Tag-Links ausblenden')
    else
      $('#section-tag-list-' + sectionId).data('show', 0).hide()
      $(this).text('Tag-Links einblenden')
    return
  return
