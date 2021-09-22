# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->

  $('#sortableWatchlistMedia').sortable({
    handle: ".card-header"
  })

  $('#sortableWatchlistMedia').on 'sortupdate', ->
    order = $.makeArray($('#sortableWatchlistMedia #card-title')).map (x) -> x.dataset.id;
    id = $('#watchlistButton').data('id');
    $.ajax
      type: 'GET',
      url: '/watchlists/rearrange',
      data: {order: order, id: id}
    return

  return