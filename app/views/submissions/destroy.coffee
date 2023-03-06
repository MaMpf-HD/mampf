<% if !@too_late %>
$('.submissionArea[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card",
                        locals: { assignment: @assignment,
                                  submission: nil } %>')
$('[data-bs-toggle="popover"]').popover()
<% else %>
alert('<%= t("submission.too_late_no_destroying") %>')
<% end %>