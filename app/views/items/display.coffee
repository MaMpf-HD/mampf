$('#video-test').empty()
$('#manuscript-test').empty()
$('#referral_explanation').val('<%= @explanation %>')
<% if @item.sort != 'link' %>
$('#link_details').hide()
<% if @item.medium.present? %>
<% if @item.medium.video.present? %>
$('#referral_video').prop('checked', true)
$('#video-ref').show()
$('#video-test').append('<%= link_to "Test",
                                     @item.video_link,
                                     class: "btn btn-outline-info btn-sm ml-3",
                                     target: :blank %>')
<% else %>
$('#referral_video').prop('checked', false)
$('#video-ref').hide()
<% end %>
<% if @item.medium.manuscript.present? %>
$('#referral_manuscript').prop('checked', true)
$('#manuscript-ref').show()
$('#manuscript-test')
  .append('<%= link_to "Test",
                       @item.manuscript_link,
                       class: "btn btn-outline-info btn-sm ml-3",
                       target: :blank %>')
<% else %>
$('#referral_manuscript').prop('checked',false)
$('#manuscript-ref').hide()
<% end %>
<% end %>
$('#item_details').show()
<% else %>
$('#item_details').hide()
$('#link_reappearance').hide()
$('#referral_description').val('<%= @item.description %>')
$('#referral_link').val('<%= @item.link %>')
<% if @reappears %>
$('#link_reappearance').show()
<% end %>
$('#link_details').show()
<% end %>
