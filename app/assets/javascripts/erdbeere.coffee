$(document).on 'turbo:load', ->
  $(".toggle-derivation").click (e) ->
    $(this).toggleClass('fa-minus-square')
    $(this).toggleClass('fa-plus-square')
  	return
  return
