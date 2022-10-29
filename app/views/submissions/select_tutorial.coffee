$('.submission-actions[data-id="<%= @submission.id %>"]').empty()
  .append('<%= j render partial: "submissions/select_tutorial",
                        locals: { submission: @submission,
                                  lecture: @lecture,
                                  tutorial: @tutorial } %>')
$('#submission_tutorial_id-<%= @submission.id %>').select2
  theme: 'bootstrap'
  language: '<%= I18n.locale %>'