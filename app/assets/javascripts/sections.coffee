# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('[id^="section-form-"] :input').on 'change', ->
    sectionId = this.dataset.id
    chapterId = this.dataset.chapter
    $('#section-basics-warning-' + sectionId).show()
    $('#lesson-modal-button-' + sectionId).hide()
    $('#details-section-' + sectionId).text('verwerfen')
    $('#details-section-' + sectionId).on 'click', (event) ->
      event.preventDefault()
      window.location.href = Routes.edit_chapter_path(chapterId, section_id: sectionId)
      return
    tags = document.getElementById('section_tag_ids_' + sectionId).selectize.getValue()
    $.ajax Routes.list_section_tags_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: sectionId
        tags: JSON.stringify(tags)
      }
    lessons = document.getElementById('section_lesson_ids_' + sectionId).selectize.getValue()
    $.ajax Routes.list_section_lessons_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: sectionId
        lessons: JSON.stringify(lessons)
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

  $('[id^="section-lesson-links-"]').on 'click', ->
    sectionId = this.dataset.id
    if $('#section-lesson-list-' + sectionId).data('show') == 0
      $('#section-lesson-list-' + sectionId).data('show', 1).show()
      $(this).text('Sitzungs-Links ausblenden')
    else
      $('#section-lesson-list-' + sectionId).data('show', 0).hide()
      $(this).text('Sitzungs-Links einblenden')
    return

  $('[id^="lesson-modal-button"]').on 'click', ->
    $.ajax Routes.lesson_modal_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        section: this.dataset.section
        from: this.dataset.from
      }
    return
  return
