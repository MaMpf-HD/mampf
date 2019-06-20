# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

disableExceptOrganizational = ->
  $('#lecture-organizational-warning').show()
  $('.fa-edit').hide()
  $('.new-in-lecture').hide()
  $('[data-toggle="collapse"]').addClass('disabled')
  return

$(document).on 'turbolinks:load', ->

  # activate all popovers
  $('[data-toggle="popover"]').popover()

  # if any input is given to the lecture form (for people in lecture),
  # disable other input
  $('#lecture-form :input').on 'change', ->
    $('#lecture-basics-warning').show()
    $('.fa-edit:not(#update-teacher-button,#update-editors-button)').hide()
    $('.new-in-lecture').hide()
    $('[data-toggle="collapse"]').addClass('disabled')
    return

  # if any input is given to the preferences form, disable other input
  $('#lecture-preferences-form :input').on 'change', ->
    $('#lecture-preferences-warning').show()
    $('[data-toggle="collapse"]').addClass('disabled')
    $('.fa-edit').hide()
    $('.new-in-lecture').hide()
    return

  # if any input is given to the organizational form, disable other input
  $('#lecture-organizational-form :input').on 'change', ->
    disableExceptOrganizational()
    return

  trixElement = document.querySelector('#lecture-concept-trix')
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

  $('#edited-media-tab a[data-toggle="tab"]').on 'shown.bs.tab', (e) ->
    sort = e.target.dataset.sort # newly activated tab
    path = $('#create-new-medium').prop('href')
    if path
      new_path = path.replace(/\?sort=.+?&/, '?sort=' + sort + '&')
      $('#create-new-medium').prop('href', new_path)
    return


  # on small mobile display, use shortened tag badges and
  # shortened course titles
  mobileDisplay = ->
    $('.tagbadge').hide()
    $('.courseMenuItem').hide()
    $('.tagbadgeshort').show()
    $('.courseMenuItemShort').show()
    $('#secondnav').show()
    $('#coursesDrop').appendTo($('#secondnav'))
    $('#notificationDropdown').appendTo($('#secondnav'))
    $('#searchField').appendTo($('#secondnav'))
    $('#second-admin-nav').show()
    $('#adminDetails').appendTo($('#second-admin-nav'))
    $('#adminUsers').appendTo($('#second-admin-nav'))
    $('#adminProfile').appendTo($('#second-admin-nav'))
    $('#teachableDrop').prependTo($('#second-admin-nav'))
    $('#adminMain').css('flex-direction', 'row')
    $('#adminHome').css('padding-right', '0.5rem')
    $('#adminCurrentLecture').css('padding-right', '0.5rem')
    return

    # on large display, use normal tag badges and course titles
  largeDisplay = ->
    $('.tagbadge').show()
    $('.courseMenuItem').show()
    $('.tagbadgeshort').hide()
    $('.courseMenuItemShort').hide()
    $('#secondnav').hide()
    $('#coursesDrop').appendTo($('#firstnav'))
    $('#notificationDropdown').appendTo($('#firstnav'))
    $('#searchField').appendTo($('#firstnav'))
    $('#second-admin-nav').hide()
    $('#teachableDrop').appendTo($('#first-admin-nav'))
    $('#adminDetails').appendTo($('#first-admin-nav'))
    $('#adminUsers').appendTo($('#first-admin-nav'))
    $('#adminProfile').appendTo($('#first-admin-nav'))
    $('#adminMain').removeAttr('style')
    $('#adminHome').removeAttr('style')
    $('#adminCurrentLecture').removeAttr('style')
    return

    # highlight tagbadges if screen is very small
  if window.matchMedia("screen and (max-width: 767px)").matches
    mobileDisplay()

  if window.matchMedia("screen and (max-device-width: 767px)").matches
    mobileDisplay()

  # mediaQuery listener for very small screens
  match_verysmall = window.matchMedia("screen and (max-width: 767px)")
  match_verysmall.addListener (result) ->
    if result.matches
      mobileDisplay()
    return

  match_verysmalldevice = window.matchMedia("screen and (max-device-width: 767px)")
  match_verysmalldevice.addListener (result) ->
    if result.matches
      mobileDisplay()
    return

  # mediaQuery listener for normal screens
  match_normal = window.matchMedia("screen and (min-width: 768px)")
  match_normal.addListener (result) ->
    if result.matches
      largeDisplay()
    return

  match_normal = window.matchMedia("screen and (min-device-width: 768px)")
  match_normal.addListener (result) ->
    if result.matches
      largeDisplay()
    return

  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $('.lecture-tag').removeClass('badge-warning').addClass('badge-light')
  $('.lecture-lesson').removeClass('badge-info').addClass('badge-secondary')
  return
