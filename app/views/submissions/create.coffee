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

<% if @progress_value.present? %>
progressBar = $('[data-testid="progress-bar"]')
progressBarInner = progressBar.find('.progress-bar')
progressBarInner.css('width', '<%= @progress_value %>%')
  .attr('aria-valuenow', '<%= @progress_value %>')
  .text('<%= @progress_value %>%')

progressText = progressBar.find('span')
<% if @progress_value == 0 %>
progressText.show()
<% else %>
progressText.hide()
<% end %>
<% end %>

<% end %>
<% else %>
alert('<%= t("submission.too_late_no_saving") %>')
<% end %>