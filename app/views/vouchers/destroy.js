console.log ("destruction complete");
$("#tutor-voucher").empty().append("<%= j render partial: 'lectures/edit/tutor_voucher', locals: { lecture: @lecture } %>");
