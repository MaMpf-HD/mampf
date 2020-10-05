<% if !@too_late %>
$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card_main",
                        locals: { assignment: @assignment,
                                  submission: nil } %>')
$('.submissionHeader[data-id="<%= @assignment.id %>"]')
	.removeClass('bg-post-it-red bg-post-it-yellow bg-post-it-green')
	.addClass('bg-submission-red')
$('#late-submission-warning').popover()
<% else %>
alert('<%= t("submission.too_late_no_destroying") %>')
<% end %>