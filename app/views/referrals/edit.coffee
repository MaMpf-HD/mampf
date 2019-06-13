# set up action box
$('#action-placeholder').empty().append(I18n.t('admin.referral.edit'))
$('#action-container').empty()
  .append('<%= j render partial: "referrals/form",
                        locals: { referral: @referral,
                                  item_selection: @item_selection,
                                  item: @item }%>')

# activate selectize and popovers
$('.selectize').selectize({ plugins: ['remove_button'] })
$('[data-toggle="popover"]').popover()