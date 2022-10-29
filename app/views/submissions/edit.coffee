<% if !@too_late %>

$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
  .append('<%= j render partial: "submissions/form",
                        locals: { submission: @submission,
                                  assignment: @assignment,
                                  lecture: @lecture } %>')
$('#submission_tutorial_id').select2
  theme: 'bootstrap'
  language: '<%= I18n.locale %>'
$('.submissionFooter[data-id!="<%= @assignment.id %>"] .btn')
  .prop('disabled', true).removeClass('btn-outline-primary')
  .removeClass('btn-outline-danger').addClass('btn-outline-secondary')

userManuscript = document.getElementById('upload-userManuscript')
userManuscriptUpload userManuscript
<% else %>
alert('<%= t("submission.too_late_no_editing") %>')
<% end %>