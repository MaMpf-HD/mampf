# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#sortableWatchlistMedia').sortable({
    handle: ".card-header"
  })

  $('#sortableWatchlistMedia').on 'sortupdate', ->
    console.log("Trying ajax.");
    console.log($.makeArray($('[id=card-title]')))
    #console.log($.makeArray($('#sortableWatchlistMedia')).map (x) -> x.dataset.id)
    $.ajax
      type: 'GET',
      url: '/watchlists/rearrange',
      success: ->
        console.log("Worked!");
      error: ->
        console.log("FUCK");
    return

  return