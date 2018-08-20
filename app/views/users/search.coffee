$('#user-search-form').hide()
$('#user-details').empty().append('<%= j render partial: "users/generic_row",
                                                locals: { user: @user } %>')
$('#other-users').hide()
$('#special-user').show()
