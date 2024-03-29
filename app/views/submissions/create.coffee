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
<% if @errors[:user_submission_joins].present? %>
alert('<%= @errors[:user_submission_joins].join(" ") %>')
<% end %>
<% else %>
$('.submissionArea[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card",
                        locals: { assignment: @assignment,
                                  submission: @submission } %>')
$('.submissionFooter .btn').prop('disabled', false)
  .removeClass('btn-outline-secondary')
$('.submissionFooter .btn').each ->
  $(this).addClass($(this).data('color'))
initBootstrapPopovers()
<% end %>
<% else %>
alert('<%= t("submission.too_late_no_saving") %>')
<% end %>