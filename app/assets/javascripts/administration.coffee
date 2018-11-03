$(document).on 'turbolinks:load', ->

  $('.dropdown-submenu > a').on 'click', (e) ->
    submenu = $(this)
    $('.dropdown-submenu .dropdown-menu').removeClass 'show'
    submenu.next('.dropdown-menu').addClass 'show'
    e.stopPropagation()
    return

  $('.dropdown').on 'hidden.bs.dropdown', ->
    # hide any open menus when parent closes
    $('.dropdown-menu.show').removeClass 'show'
    return

return
