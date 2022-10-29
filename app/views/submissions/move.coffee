<% if @old_tutorial == @tutorial %>
$('.submission-actions[data-id="<%= @submission.id %>"]').empty()
  .append('<%= j render partial: "submissions/other_actions",
                        locals: { submission: @submission } %>')
<% else %>
$('.submission-row[data-id="<%= @submission.id %>"]').remove()
<% end %>