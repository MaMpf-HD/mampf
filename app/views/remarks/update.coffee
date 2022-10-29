<% if @success %>
$('#remark-basics-warning').addClass 'no_display'
$('#remark-basics-options').addClass 'no_display'
<% else %>
alert('<%= I18n.t("admin.remark.save_error") %>')
<% end %>
