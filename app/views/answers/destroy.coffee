<% if @success %>
$('#answer-card-<%= @id %>').remove()
<% else %>
alert I18n.t('admin.answer.delete_error')
<% end %>
