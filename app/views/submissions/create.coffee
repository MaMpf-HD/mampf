<% if !@too_late %>
<% if @errors.present? %>
# clean up from previous error messages
$('#submission-tutorial-error').empty()
# display error message
<% if @errors[:tutorial].present? %>
$('#submission-tutorial-error')
  .append('<%= @errors[:tutorial].join(" ") %>').show()
<% end %>
<% if @errors[:manuscript].present? %>
alert('<%= @errors[:manuscript].join(" ") %>')
<% end %>
<% else %>
$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card_main",
                        locals: { assignment: @assignment,
                                  submission: @submission } %>')
$('.submissionHeader[data-id="<%= @assignment.id %>"]')
	.removeClass('bg-submission-red bg-submission-yellow bg-submission-green')
	.addClass('<%= submission_color(@submission, @assignment) %>')
$('.submissionFooter .btn').prop('disabled', false)
  .removeClass('btn-outline-secondary')
$('.submissionFooter .btn').each ->
  $(this).addClass($(this).data('color'))
$('#late-submission-warning').popover()
<% end %>
<% else %>
alert('<%= t("submission.too_late_no_saving") %>')
<% end %>