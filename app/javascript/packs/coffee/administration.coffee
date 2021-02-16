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
  console.log("Hello!")
return
