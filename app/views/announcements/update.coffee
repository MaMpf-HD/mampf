<% if @errors.present? %>
$('#announcement-error').empty().append('<%= @errors %>').show()
$('#announcement_details').addClass('is-invalid')
<% else %>
$('#row-announcement-<%= @id %>').addClass('row').empty()
  .append('<%= j render partial: "announcements/row",
                        locals: { announcement: @announcement } %>')
<% end %>