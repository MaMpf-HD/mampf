<% if @errors == 'voted already' %>
$('body').empty().append('<%= j render partial: "votes/create/voted_already",
                                       locals: { clicker: @clicker } %>')
<% else %>
$('body').empty().append('<%= j render partial: "votes/create/thankyou",
                                       locals: { clicker: @clicker } %>')
<% end %>