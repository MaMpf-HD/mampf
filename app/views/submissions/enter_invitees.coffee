<% if !@too_late %>
$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/enter_invitees",
                        locals: { submission: @submission,
					                        assignment: @assignment,
					                        lecture: @lecture } %>')
$('#submission_invitee_ids').select2
  theme: 'bootstrap'
  language: '<%= I18n.locale %>'
$('.submissionFooter[data-id!="<%= @assignment.id %>"] .btn')
  .prop('disabled', true).removeClass('btn-outline-primary')
  .removeClass('btn-outline-danger').addClass('btn-outline-secondary')
<% else %>
alert('<%= t("submission.too_late_no_inviting") %>')
<% end %>