$('#action-placeholder').empty().append('Referenz bearbeiten')
$('#action-container').empty()
  .append('<%= j render partial: "referrals/form",
                        locals: { referral: @referral,
                                  item_selection: @item_selection,
                                  item: @item }%>')
$('.selectize').selectize({ plugins: ['remove_button'] })
$('[data-toggle="popover"]').popover()