<% if @success %>
$card = $('.teachableCard[data-type="<%= @teachable.class %>"][data-id="<%= @teachable.id %>"][data-parent="<%= @parent %>"]')
<% if @parent.in?(['inactive', 'current_subscribed']) %>
$card.remove()
<% else %>
$card.empty()
  .append('<%= j render partial: "main/start/teachable_card",
                        locals: { teachable: @teachable,
                                  current: true,
                                  subscribed: false,
                                  parent: @parent } %>')
<% end %>
<% end %>