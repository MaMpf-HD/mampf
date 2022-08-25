$('.submission-actions[data-id="<%= @submission.id %>"]').empty()
  .append('<%= j render partial: "submissions/select_tutorial",
                        locals: { submission: @submission,
                                  lecture: @lecture,
                                  tutorial: @tutorial } %>')

new TomSelect('#submission_tutorial_id-<%= @submission.id %>',
  sortField:
    field: 'text'
    direction: 'asc'
  render:
    no_results: (data, escape) ->
      '<div class="no-results"><%= t("basics.no_results") %></div>'
)