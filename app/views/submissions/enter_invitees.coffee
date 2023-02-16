<% if !@too_late %>
$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/enter_invitees",
                        locals: { submission: @submission,
					                        assignment: @assignment,
					                        lecture: @lecture } %>')

new TomSelect('#submission_invitee_ids',
  sortField:
    field: 'text'
    direction: 'asc'
  render:
    no_results: (data, escape) ->
      '<div class="no-results"><%= t("basics.no_results") %></div>'
)

$('.submissionFooter[data-id!="<%= @assignment.id %>"] .btn')
  .prop('disabled', true).removeClass('btn-outline-primary')
  .removeClass('btn-outline-danger').addClass('btn-outline-secondary')
<% else %>
alert('<%= t("submission.too_late_no_inviting") %>')
<% end %>