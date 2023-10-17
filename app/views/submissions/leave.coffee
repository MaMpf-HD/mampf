<% if !@too_late %>
$('.submissionArea[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card",
                        locals: { assignment: @assignment,
                                  submission: nil } %>')
initBootstrapPopovers()
<% else %>
alert('<%= t("submission.too_late_no_saving") %>')
<% end %>