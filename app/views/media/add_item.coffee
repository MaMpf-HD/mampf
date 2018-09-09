$('#action-placeholder').empty().append('Item anlegen')
$('#action-container').empty()
  .append('<%= j render partial: "items/form",
                        locals: { item: @item }%>')
$('.selectize').selectize()
