# prepare action box
$('#action-placeholder').empty().append('<%= I18n.t("admin.item.create") %>')
# render item form to action box
$('#action-container').empty()
  .append('<%= j render partial: "items/form",
                        locals: { item: @item }%>')
# activate selectize and popovers
$('.selectize').each ->
  new TomSelect("#"+this.id,{ plugins: ['remove_button'] })
$('[data-bs-toggle="popover"]').popover()
# bugfix for selectize (which sometimes renders the prompt with a zero width)
$('input[id$="-selectized"]').css('width', '100%')