<% if @success %>
$card = $('.lectureCard[data-id="<%= @lecture.id %>"][data-parent="<%= @parent %>"]')
$card.empty()
  .append('<%= j render partial: "main/start/lecture_card",
                        locals: { lecture: @lecture,
                                  current: @current,
                                  subscribed: false,
                                  own: @own,
                                  parent: @parent } %>')
<% end %>
