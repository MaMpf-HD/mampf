<% if @tutorial.destroyed? %>
$('.tutorialRow[data-id="<%= @tutorial.id %>"').remove()
<% if @lecture.tutorials.none? %>
$('#tutorialListHeader').hide()
<% end %>
<% else %>
alert('<%= t("controllers.tutorials.destruction_failed") %>')
<% end %>