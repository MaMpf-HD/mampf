<% if @errors.present? %>
<% if @errors[:correction].present? %>
alert('<%= @errors[:correction].join(" ") %>')
<% end %>
<% else %>
$('.correction-column[data-id="<%= @submission.id %>"]').empty()
  .append('<%= j render partial: "submissions/correction",
                        locals: { submission: @submission } %>')
<% end %>