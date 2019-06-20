$('#identified_tag_titles select').empty()
<% I18n.available_locales.each do |l| %>
<% if @common_titles[l] %>
<% @common_titles[l].each do |t| %>
$('#identified_tag_titles select[data-locale="<%= l.to_s %>"]')
  .append($('<option>',
    value: '<%= t %>'
    text: '<%= t %>'))
<% end %>
<% end %>
$('#identified_tag_titles select[data-locale="<%= l.to_s %>"] option[value=""]').remove()
<% if l.in?(@common_titles[:contradictions]) %>
$('.titleWarning[data-locale="<%= l.to_s %>"]').show()
<% else %>
$('.titleWarning[data-locale="<%= l.to_s %>"]').hide()
<% end %>
<% end %>
