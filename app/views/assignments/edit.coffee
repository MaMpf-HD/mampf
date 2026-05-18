$('.assignmentRow[data-id="<%= @assignment.id %>"')
  .replaceWith('<%= j render partial: "assignments/form",
                      locals: { assignment: @assignment } %>')

new TomSelect('#assignment_medium_id_<%= @assignment.id %>',
  sortField:
    field: 'text'
    direction: 'asc'
  plugins: ['remove_button']
  render:
    no_results: (data, escape) ->
      '<div class="no-results"><%= t("basics.no_results") %></div>'
)

<% unless @assignment.medium %>
# make sure that no medium is preselected
$('#assignment_medium_id_<%= @assignment.id %>').val(null).trigger('change')
<% end %>
