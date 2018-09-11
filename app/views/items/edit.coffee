$('#action-placeholder').empty().append('Item bearbeiten')
$('#action-container').empty()
  .append('<%= j render partial: "items/form",
                        locals: { item: @item }%>')
$('#item_sort').trigger('change')
$('.selectize').selectize()
