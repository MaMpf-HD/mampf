# prepare action box
$('#action-placeholder').empty().append('Eintrag anlegen')
# render item form to action box
$('#action-container').empty()
  .append('<%= j render partial: "items/form",
                        locals: { item: @item }%>')
# activate selectize and popovers
$('.selectize').selectize({ plugins: ['remove_button'] })
$('[data-toggle="popover"]').popover()
# bugfix for selectize (which sometimes renders the prompt with a zero width)
$('input[id$="-selectized"]').css('width', '100%')