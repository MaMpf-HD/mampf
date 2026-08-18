<% if @parent == "dashboard" %>
$card = $('.lecture-dashboard-card[data-lecture-id="<%= @lecture.id %>"]')
$card.replaceWith('<%= j render(LectureDashboardCardComponent.new(lecture: @lecture, user: current_user)) %>')
<% else %>
$card = $('.lectureCard[data-id="<%= @lecture.id %>"][data-parent="<%= @parent %>"]')
$card.empty()
  .append('<%= j render partial: "main/start/lecture_card",
                        locals: { lecture: @lecture,
                                  current: @current,
                                  subscribed: true,
                                  parent: @parent } %>')
<% end %>
$('#lecturesDropdown').empty()
	.append('<%= j render partial: "shared/dropdown_lectures",
												locals: { lecture: nil } %>')
