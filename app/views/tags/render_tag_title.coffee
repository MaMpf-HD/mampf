# An option takes value and text as text, so a title is escaped for the string
# only.
$('#identified_tag_titles select').empty()
<% I18n.available_locales.each do |l| %>
<% if @common_titles[l] %>
<% @common_titles[l].each do |t| %>
$('#identified_tag_titles select[data-locale="<%= l.to_s %>"]')
  .append($('<option>',
    value: '<%= raw j(t) %>'
    text: '<%= raw j(t) %>'))
<% end %>
<% end %>
$('#identified_tag_titles select[data-locale="<%= l.to_s %>"] option[value=""]').remove()
<% if l.in?(@common_titles[:contradictions]) %>
$('.titleWarning[data-locale="<%= l.to_s %>"]').show()
<% else %>
$('.titleWarning[data-locale="<%= l.to_s %>"]').hide()
<% end %>
<% end %>
