<% if @collapse_id == 'collapseCurrentStuff' %>
<% if @lectures.any? %>
$('#<%= "#{@collapse_id}Content" %>').empty()
  .append('<%= j render partial: "main/start/lecture",
                        collection: @lectures,
                        locals: { current: true,
                                  subscribed: true,
                                  parent: "current_subscribed" },
                        as: :lecture %>')
$('#emptyCurrentStuff').hide()
<% else %>
$('#emptyCurrentStuff').show()
<% end %>
<% elsif @collapse_id == 'collapseInactiveLectures' %>
<% if @lectures.any? %>
$('#<%= "#{@collapse_id}Content" %>').empty()
  .append('<%= j render partial: "main/start/lecture",
                        collection: @lectures,
                        locals: { current: false,
                                  subscribed: true,
                                  parent: "inactive" },
                        as: :lecture %>')
$('#emptyInactiveLectures').hide()
<% else %>
$('#emptyInactiveLectures').show()
<% end %>
<% elsif @collapse_id == 'collapseAllCurrent' %>
$('#<%= "#{@collapse_id}Content" %>').empty()
<% @lectures.each do |l| %>
$('#<%= "#{@collapse_id}Content" %>')
  .append('<%= j render partial: "main/start/lecture",
                        locals: { lecture: l,
                                  current: true,
                                  subscribed: l.subscribed_by?(current_user),
                                  parent: "all_current" } %>')
<% end %>
<% if @lectures.empty? %>
$('#emptyAllCurrent').show()
<% else %>
$('#emptyAllCurrent').hide()
<% end %>
<% end %>
# the next lines are a hotfix for Firefox since it screws up the
# view
if window.matchMedia("screen and (max-width: 767px)")
  .matches || window.matchMedia("screen and (max-device-width: 767px)").matches
    document.getElementById('<%= @link %>').scrollIntoView()