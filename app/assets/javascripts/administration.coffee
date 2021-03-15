$(document).on 'turbolinks:load', ->

  # disable active state for menu entries when submenus are triggered
  $('.dropdown-submenu > a').on 'click', (e) ->
    submenu = $(this)
    $('.dropdown-submenu .dropdown-menu').removeClass 'show'
    submenu.next('.dropdown-menu').addClass 'show'
    e.stopPropagation()
    return

  # hide any open menus when parent closes
  $('.dropdown').on 'hidden.bs.dropdown', ->
    $('.dropdown-menu.show').removeClass 'show'
    return

  $('#new-course-button').on 'click', ->
    $('#new-course-area').show()
    $('.admin-index-button').hide()
    return

  $('#cancel-new-course').on 'click', ->
    $('#new-course-area').hide()
    $('#new-course-button').show()
    $('.admin-index-button').show()
    return

  $('input:radio[name="search_teachable_radio"]').on 'change',  ->
    if this.id == 'search_course_radio'
      $('#lectureSearchArea').hide()
      $('#courseSearchArea').show()
      $('#programSearch').insertAfter($('#editorSearch'))
      $('#fullTextSearch').insertAfter($('#programSearch'))
      $('#hitsPerPage').insertAfter($('#fullTextSearch'))
    else
      $('#courseSearchArea').hide()
      $('#lectureSearchArea').show()
      $('#programSearch').insertAfter($('#termSearch'))
      $('#fullTextSearch').insertAfter($('#teacherSearch'))
      $('#hitsPerPage').insertAfter($('#fullTextSearch'))
    return

return
