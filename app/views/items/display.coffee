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

# fill explanation text area
$('#referral_explanation').val('<%= @explanation %>')
$('#explanation_details').show()

# do not show link details if item is not a link
<% if @item.sort != 'link' %>
$('#link_details').hide()


<% if @item.medium.present? %>

$('#item_details').empty()
  .append('<%= j render partial: "referrals/item_details",
                        locals: { item: @item } %>')

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

# activate popovers
$('[data-bs-toggle="popover"]').popover()