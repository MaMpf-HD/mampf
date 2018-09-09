$('#action-placeholder').empty().append('Referenz bearbeiten')
$('#action-container').empty()
  .append('<%= j render partial: "referrals/form",
                        locals: { referral: @referral }%>')
$('.selectize').selectize()
