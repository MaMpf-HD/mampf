$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/join",
                        locals: { assignment: @assignment } %>')
$('.submissionFooter[data-id!="<%= @assignment.id %>"] .btn')
  .prop('disabled', true).removeClass('btn-outline-primary')
  .removeClass('btn-outline-danger').addClass('btn-outline-secondary')