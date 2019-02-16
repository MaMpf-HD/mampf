# clean up from previous error messages
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

# fill explanation text area
$('#referral_explanation').val('<%= @explanation %>')
$('#explanation_details').show()

# do not show link details if item is not a link
<% if @item.sort != 'link' %>
$('#link_details').hide()


<% if @item.medium.present? %>

# if item belongs to a medium with video, show this and provide link
# to a button that provides a test for the video link
<% if @item.sort != 'pdf_destination' && @item.medium.video.present? %>
$('#video-ref').show()
$('#video-test').append('<%= link_to "Test",
                                     @item.video_link,
                                     class: "badge badge-info",
                                     target: :blank %>')
<% else %>
$('#video-ref').hide()
<% end %>

# if item belongs to a medium with manuscript, show this and provide link
# to a button that provides a test for the manuscript link
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

# if item belongs to a medium with an external link, show this and provide link
# to a button that provides a test for the manuscript link
<% if @item.sort != 'pdf_destination' &&
        @item.medium.external_reference_link.present? %>
$('#medium-link-ref').show()
$('#medium-link-test')
  .append('<%= link_to "Test",
                       @item.medium_link,
                       class: "badge badge-info",
                       target: :blank %>')
<% else %>
$('#medium-link-ref').hide()
<% end %>

<% if @item.medium.visible? %>
$('#unpublished_medium_item').hide()
$('#locked_medium_item').hide()
<% elsif !@item.medium.published_with_inheritance? %>
$('#unpublished_medium_item').show()
$('#locked_medium_item').hide()
<% else %>
$('#unpublished_medium_item').hide()
$('#locked_medium_item').show()
<% end %>

# end of the case where the item is associated to a medium
<% end %>
$('#item_details').show()
# end of the case where the sort of the item is not 'link'
<% else %>
# item' sort is 'link'
# clean up from previous items and inject information from the present one
$('#item_details').hide()
$('#link_reappearance_title').hide()
$('#link_reappearance_link').hide()
$('#referral_description').val('<%= @item.description %>')
$('#referral_link').val('<%= @item.link %>')

# show warnings if the link is already referred to in some other place
# (editing the link and its title has aglobal effect)
<% if @reappears %>
$('#link_reappearance_title').show()
$('#link_reappearance_link').show()
<% end %>

$('#link_details').show()
<% end %>
