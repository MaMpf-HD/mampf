console.log '<%= @collapse_id %>'
<% if @collapse_id == 'collapseCurrentStuff' %>
$('#<%= "#{@collapse_id}Content" %>').empty()
  .append('<%= j render partial: "main/start/teachable",
                        collection: @teachables,
                        locals: { current: true,
                                  subscribed: true,
                                  parent: "current_subscribed" },
                        as: :teachable %>')
<% elsif @collapse_id == 'collapseInactiveLectures' %>
$('#<%= "#{@collapse_id}Content" %>').empty()
  .append('<%= j render partial: "main/start/teachable",
                        collection: @teachables,
                        locals: { current: false,
                                  subscribed: true,
                                  parent: "current_subscribed" },
                        as: :teachable %>')
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
<% end %>