<% if @success %>
$('#question-basics-warning').addClass 'no_display'
$('#question-basics-options').addClass 'no_display'
<% else %>
alert I18n.t('admin.question.save_error')
<% end %>
