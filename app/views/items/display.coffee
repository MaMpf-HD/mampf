$('#referral_start_time').removeClass('is-invalid')
$('#start-time-error').empty()
$('#referral_end_time').removeClass('is-invalid')
$('#end-time-error').empty()
$('#referral_manuscript').removeClass('is-invalid')
$('#referral_video').removeClass('is-invalid')
$('#ref-error').empty()
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
<% if @item.sort != 'link' %>
$('#link_details').hide()
<% if @item.medium.present? %>
<% if @item.sort != 'pdf_destination' && @item.medium.video.present? %>
$('#referral_video').prop('checked', true)
$('#video-ref').show()
$('#video-test').append('<%= link_to "Test",
                                     @item.video_link,
                                     class: "badge badge-info ml-4",
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
                       class: "badge badge-info ml-4",
                       target: :blank %>')
<% else %>
$('#referral_manuscript').prop('checked',false)
$('#manuscript-ref').hide()
<% end %>
<% if @item.sort != 'pdf_destination' && @item.medium.external_reference_link.present? %>
$('#referral_medium_link').prop('checked', true)
$('#medium-link-ref').show()
$('#medium-link-test')
  .append('<%= link_to "Test",
                       @item.medium_link,
                       class: "badge badge-info ml-4",
                       target: :blank %>')
<% else %>
$('#referral_medium_link').prop('checked', false)
$('#medium-link-ref').hide()
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
