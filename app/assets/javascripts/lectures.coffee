# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

disableExceptOrganizational = ->
  $('#lecture-organizational-warning').show()
  $('#organizational_collapse_button').hide()
  $('#forum-buttons .btn').addClass('disabled')
  $('#new-announcement-button').addClass('disabled')
  $('#lecture-preferences-form input').prop('disabled', true)
  $('#lecture-preferences-form select').prop('disabled', true)
  $('#lecture-form input').prop('disabled', true)
  $('#lecture-form .selectized').each ->
    this.selectize.disable()
    return
  $('.fa-edit').hide()
  $('.new-in-lecture').hide()
  return

$(document).on 'turbolinks:load', ->

  # activate all popovers
  $('[data-toggle="popover"]').popover()

  # if any input is given to the lecture form (for people in lecture),
  # disable other input
  $('#lecture-form :input').on 'change', ->
    $('#lecture-basics-warning').show()
    $('#people_collapse_button').hide()
    $('.fa-edit:not(#update-teacher-button,#update-editors-button)').hide()
    $('.new-in-lecture').hide()
    $('#forum-buttons .btn').addClass('disabled')
    $('#new-announcement-button').addClass('disabled')
    $('#lecture-organizational-form input').prop('disabled', true)
    $('#lecture-preferences-form input').prop('disabled', true)
    $('#lecture-preferences-form select').prop('disabled', true)
    return

  # if any input is given to the preferences form, disable other input
  $('#lecture-preferences-form :input').on 'change', ->
    $('#lecture-preferences-warning').show()
    $('#preferences_collapse_button').hide()
    $('#lecture-form input').prop('disabled', true)
    $('#lecture-organizational-form input').prop('disabled', true)
    $('#forum-buttons .btn').addClass('disabled')
    $('#new-announcement-button').addClass('disabled')
    $('#lecture-form .selectized').each ->
      this.selectize.disable()
      return
    $('.fa-edit').hide()
    $('.new-in-lecture').hide()

  # if any input is given to the organizational form, disable other input
  $('#lecture-organizational-form :input').on 'change', ->
    disableExceptOrganizational()
    return

  trixElement = document.querySelector('trix-editor')
  if trixElement?
    trixElement.addEventListener 'trix-change', ->
      disableExceptOrganizational()
      return

  # if absolute numbering box is checked/unchecked, enable/disable selection of
  # start section
  $('#lecture_absolute_numbering').on 'change', ->
    if $(this).prop('checked')
      $('#lecture_start_section').prop('disabled', false)
    else
      $('#lecture_start_section').prop('disabled', true)
    return

  # rewload current page if lecture basics editing is cancelled
  $('#lecture-basics-cancel').on 'click', ->
    location.reload()
    return

  # rewload current page if lecture preferences editing is cancelled
  $('#cancel-lecture-preferences').on 'click', ->
    location.reload()
    return

   # rewload current page if lecture preferences editing is cancelled
  $('#cancel-lecture-organizational').on 'click', ->
    location.reload()
    return

  # hide the media tab if hide media button is clicked
  $('#hide-media-button').on 'click', ->
    $('#lecture-media-card').hide()
    $('#lecture-content-card').removeClass('col-xxxl-9')
    $('#show-media-button').show()
    return

  # display the media tab if show media button is clicked
  $('#show-media-button').on 'click', ->
    $('#lecture-content-card').addClass('col-xxxl-9')
    $('#lecture-media-card').show()
    $('#show-media-button').hide()
    return

  # mousenter over a medium -> colorize lessons and tags
  $('[id^="lecture-medium_"]').on 'mouseenter', ->
    if this.dataset.type == 'Lesson'
      lessonId = this.dataset.id
      $('.lecture-lesson[data-id="'+lessonId+'"]')
        .removeClass('badge-secondary')
        .addClass('badge-info')
    tags = $(this).data('tags')
    for t in tags
      $('.lecture-tag[data-id="'+t+'"]').removeClass('badge-light')
        .addClass('badge-warning')
    return

  # mouseleave over lesson -> restore original color of lessons and tags
  $('[id^="lecture-medium_"]').on 'mouseleave', ->
    if this.dataset.type == 'Lesson'
      lessonId = this.dataset.id
      $('.lecture-lesson[data-id="'+lessonId+'"]').removeClass('badge-info')
        .addClass('badge-secondary')
    tags = $(this).data('tags')
    for t in tags
      $('.lecture-tag[data-id="'+t+'"]').removeClass('badge-warning')
        .addClass('badge-light')
    return

  # mouseenter over lesson -> colorize tags
  $('[id^="lecture-lesson_"]').on 'mouseenter', ->
    tags = $(this).data('tags')
    for t in tags
      $('.lecture-tag[data-id="'+t+'"]').removeClass('badge-light')
        .addClass('badge-warning')
    return

  # mouseleave over lesson -> restore original color of tags
  $('[id^="lecture-lesson_"]').on 'mouseleave', ->
    tags = $(this).data('tags')
    for t in tags
      $('.lecture-tag[data-id="'+t+'"]').removeClass('badge-warning')
        .addClass('badge-light')
    return

  # mouseenter over tag -> colorize lessons
  $('[id^="lecture-tag_"]').on 'mouseenter', ->
    lessons = $(this).data('lessons')
    for l in lessons
      $('.lecture-lesson[data-id="'+l+'"]').removeClass('badge-secondary')
        .addClass('badge-info')
    return

  # mouseleave over tag -> restore original color of lessons
  $('[id^="lecture-tag_"]').on 'mouseleave', ->
    lessons = $(this).data('lessons')
    for l in lessons
      $('.lecture-lesson[data-id="'+l+'"]').removeClass('badge-info')
        .addClass('badge-secondary')
    return

  $('.content-mode').on 'change', ->
    console.log 'Hi!'
    mode = if this.id == 'video-based' then 'video' else 'manuscript'
    lectureId = $(this).data('lecture')
    console.log mode
    $.ajax Routes.update_content_mode_path(lectureId),
      type: 'POST'
      dataType: 'script'
      data: {
        mode: mode
      }
    return
  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $('.lecture-tag').removeClass('badge-warning').addClass('badge-light')
  $('.lecture-lesson').removeClass('badge-info').addClass('badge-secondary')
  return
