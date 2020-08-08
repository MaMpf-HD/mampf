<% if @collapse_id == 'collapseCurrentStuff' %>
<% if @teachables.any? %>
$('#<%= "#{@collapse_id}Content" %>').empty()
  .append('<%= j render partial: "main/start/teachable",
                        collection: @teachables,
                        locals: { current: true,
                                  subscribed: true,
                                  parent: "current_subscribed" },
                        as: :teachable %>')
$('#emptyCurrentStuff').hide()
<% else %>
$('#emptyCurrentStuff').show()
<% end %>
<% elsif @collapse_id == 'collapseInactiveLectures' %>
<% if @teachables.any? %>
$('#<%= "#{@collapse_id}Content" %>').empty()
  .append('<%= j render partial: "main/start/teachable",
                        collection: @teachables,
                        locals: { current: false,
                                  subscribed: true,
                                  parent: "inactive" },
                        as: :teachable %>')
$('#emptyInactiveLectures').hide()
<% else %>
$('#emptyInactiveLectures').show()
<% end %>
<% elsif @collapse_id == 'collapseAllCurrent' %>
$('#<%= "#{@collapse_id}Content" %>').empty()
<% @teachables.each do |l| %>
$('#<%= "#{@collapse_id}Content" %>')
  .append('<%= j render partial: "main/start/teachable",
                        locals: { teachable: l,
                                  current: true,
                                  subscribed: l.subscribed_by?(current_user),
                                  parent: "all_current" } %>')
<% end %>
<% if @teachables.empty? %>
$('#emptyAllCurrent').show()
<% else %>
$('#emptyAllCurrent').hide()
<% end %>
<% end %>