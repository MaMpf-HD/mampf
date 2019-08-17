<% if @success %>
<% if @no_solution_update %>
$('#question-basics-warning').addClass 'no_display'
$('#question-basics-options').addClass 'no_display'
<% else %>
$('#question-solution-warning').addClass 'no_display'
$('#question-solution-options').addClass 'no_display'
<% end %>
<% else %>
alert('<%= I18n.t("admin.question.save_error") %>')
<% end %>
