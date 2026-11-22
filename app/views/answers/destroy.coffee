<% if @success %>
$('#answer-card-<%= @id.to_i %>').remove()
<% else %>
alert('<%= I18n.t("admin.answer.delete_error") %>')
<% end %>
