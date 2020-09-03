<% if @success %>
$card = $('.lectureCard[data-id="<%= @lecture.id %>"][data-parent="<%= @parent %>"]')
<% if @parent.in?(['inactive', 'current_subscribed']) %>
$card.remove()
<% if @none_left %>
<% if @parent == 'current_subscribed' %>
$('#emptyCurrentStuff').show()
<% else %>
$('#emptyInactiveLectures').show()
<% end %>
<% end %>
<% else %>
$card.empty()
  .append('<%= j render partial: "main/start/lecture_card",
                        locals: { lecture: @lecture,
                                  current: @current,
                                  subscribed: false,
                                  parent: @parent } %>')
<% end %>
<% end %>