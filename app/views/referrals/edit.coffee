# set up action box
$('#action-placeholder').empty().append('<%= I18n.t("admin.referral.edit") %>')
$('#action-container').empty()
  .append('<%= j render partial: "referrals/form",
                        locals: { referral: @referral,
                                  item_selection: @item_selection,
                                  item: @item }%>')

# activate selectize and popovers
$('.selectize').each ->
  new TomSelect("#"+this.id,{ plugins: ['remove_button'] })
$('[data-bs-toggle="popover"]').popover()