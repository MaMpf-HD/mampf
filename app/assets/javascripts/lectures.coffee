# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('[data-toggle="popover"]').popover()

  # if any input is given to the lecture form, disable other input
  $('#lecture-form :input').on 'change', ->
    $('#lecture-basics-warning').show()
    $('#people_collapse_button').hide()
    $('.fa-edit:not(#update-teacher-button,#update-editors-button)').hide()
    $('.new-in-lecture').hide()
    return

  # if any input is given to the preferences form, disable other input
  $('#lecture-preferences-form :input').on 'change', ->
    $('#lecture-preferences-warning').show()
    $('#preferences_collapse_button').hide()
    $('#lecture-form input').prop('disabled', true)
    $('#lecture-form .selectized').each ->
      this.selectize.disable()
      return
    $('.fa-edit').hide()
    $('.new-in-lecture').hide()

  # if absolute numbering box is chekced/unchecked, enable/disable selection of
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

  # hide the media tab if hide media button is clicked
  $('#hide-media-button').on 'click', ->
    $('#lecture-media-card').hide()
    $('#lecture-content-card').removeClass('col-9').addClass('col-12')
    $('#show-media-button').show()
    return

  # display the media tab if show media button is clicked
  $('#show-media-button').on 'click', ->
    $('#lecture-content-card').removeClass('col-12').addClass('col-9')
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
  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $('.lecture-tag').removeClass('badge-warning').addClass('badge-light')
  $('.lecture-lesson').removeClass('badge-info').addClass('badge-secondary')
  return
