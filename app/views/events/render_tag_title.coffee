<% I18n.available_locales.each do |l| %>
$('#identified_tag_titles input[data-locale="<%= l.to_s %>"]').val('<%= @common_titles[l] %>')
<% if l.in?(@common_titles[:contradictions]) %>
$('.titleWarning[data-locale="<%= l.to_s %>"]').show()
<% else %>
$('.titleWarning[data-locale="<%= l.to_s %>"]').hide()
<% end %>
<% end %>
