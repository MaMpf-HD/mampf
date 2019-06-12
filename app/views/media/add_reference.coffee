# prepare action box
$('#action-placeholder').empty().append(I18n.t('admin.referral.create'))
# render referral form to action box
$('#action-container').empty()
  .append('<%= j render partial: "referrals/form",
                        locals: { referral: @referral,
                                  item_selection: @item_selection,
                                  item: @item }%>')
# activate selectize and popovers
$('.selectize').selectize({ plugins: ['remove_button'] })
$('[data-toggle="popover"]').popover()
# bugfix for selectize (which sometimes renders the prompt with a zero width)
$('input[id$="-selectized"]').css('width', '100%')