<% if @error.nil? %>
$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/card_main",
                        locals: { assignment: @assignment,
                                  submission: @submission } %>')
$('.submissionFooter .btn').prop('disabled', false)
  .removeClass('btn-outline-secondary')
$('.submissionFooter .btn').each ->
  $(this).addClass($(this).data('color'))
$('.submissionHeader[data-id="<%= @assignment.id %>"]')
	.removeClass('bg-submission-red bg-submission-yellow bg-submission-green')
	.addClass('<%= submission_color(@submission, @assignment) %>')
$('#late-submission-warning').popover()
<% else %>
$('#join_code').addClass('is-invalid')
$('#submission-code-error').empty().append('<%= @error %>').show()
<% end %>
