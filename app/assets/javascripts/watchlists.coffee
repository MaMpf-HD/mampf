# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbo:load', ->

  id = $('#watchlistButton').data('id')
  owned = $('#watchlistButton').data('owned')

  if owned
    $('#sortableWatchlistMedia').sortable handle: '.card-header'

  $('#sortableWatchlistMedia').on 'sortupdate', ->
    params = new URLSearchParams(window.location.search)
    order = $.makeArray($('#sortableWatchlistMedia #card-title')).map (x) -> x.dataset.id
    $.ajax
      type: 'GET'
      url: '/watchlists/rearrange'
      data:
        order: order
        id: id
        reverse: params.get('reverse')
        per: params.get('per')
        page: params.get('page') || '1'
    return

  $('#watchlistVisiblityCheck').on 'change', ->
    id = $('#watchlistButton').data('id')
    checked = $(this).is(':checked')
    $.ajax
      type: 'GET',
      url: '/watchlists/change_visiblity',
      data: {id: id, public: checked}
    return

  return