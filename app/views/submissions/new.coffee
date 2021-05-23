$('.submissionMain[data-id="<%= @assignment.id %>"]').empty()
	.append('<%= j render partial: "submissions/form",
												locals: { submission: @submission,
                                  assignment: @assignment,
                                  lecture: @lecture } %>')

$('#submission_tutorial_id').select2
  theme: 'bootstrap'
  language: '<%= I18n.locale %>'

$('#submission_invitee_ids').select2
  theme: 'bootstrap'
  language: '<%= I18n.locale %>'

$('.submissionFooter[data-id!="<%= @assignment.id %>"] .btn')
  .prop('disabled', true).removeClass('btn-outline-primary')
  .removeClass('btn-outline-danger').addClass('btn-outline-secondary')

userManuscript = document.getElementById('upload-userManuscript')
window.userManuscriptUpload userManuscript

# make uppy upload buttons look like bootstrap
$('.uppy-FileInput-btn').removeClass('uppy-FileInput-btn')
  .addClass('btn btn-sm btn-outline-secondary')