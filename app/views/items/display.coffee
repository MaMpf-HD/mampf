$('#referral_start_time').removeClass('is-invalid')
$('#start-time-error').empty()
$('#referral_end_time').removeClass('is-invalid')
$('#end-time-error').empty()
$('#referral_link').removeClass('is-invalid')
$('#link-error').empty()
$('#referral_description').removeClass('is-invalid')
$('#description-error').empty()
$('#referral_explanation').removeClass('is-invalid')
$('#explanation-error').empty()
$('#video-test').empty()
$('#manuscript-test').empty()
$('#medium-link-test').empty()
$('#referral_explanation').val('<%= @explanation %>')
$('#explanation_details').show()
<% if @item.sort != 'link' %>
$('#link_details').hide()
<% if @item.medium.present? %>
<% if @item.sort != 'pdf_destination' && @item.medium.video.present? %>
$('#video-ref').show()
$('#video-test').append('<%= link_to "Test",
                                     @item.video_link,
                                     class: "badge badge-info",
                                     target: :blank %>')
<% else %>
$('#video-ref').hide()
<% end %>
<% if @item.medium.manuscript.present? %>
$('#manuscript-ref').show()
$('#manuscript-test')
  .append('<%= link_to "Test",
                       @item.manuscript_link,
                       class: "badge badge-info",
                       target: :blank %>')
<% else %>
$('#manuscript-ref').hide()
<% end %>
<% if @item.sort != 'pdf_destination' && @item.medium.external_reference_link.present? %>
$('#medium-link-ref').show()
$('#medium-link-test')
  .append('<%= link_to "Test",
                       @item.medium_link,
                       class: "badge badge-info",
                       target: :blank %>')
<% else %>
$('#medium-link-ref').hide()
<% end %>
<% end %>
$('#item_details').show()
<% else %>
$('#item_details').hide()
$('#link_reappearance_title').hide()
$('#link_reappearance_link').hide()
$('#referral_description').val('<%= @item.description %>')
$('#referral_link').val('<%= @item.link %>')
<% if @reappears %>
$('#link_reappearance_title').show()
$('#link_reappearance_link').show()
<% end %>
$('#link_details').show()
<% end %>
