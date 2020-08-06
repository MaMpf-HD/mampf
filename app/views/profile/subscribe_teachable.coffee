$('#subscriptionModal').modal('show')
<% if @passphrase %>
$('#passphrase-error').text('<%= t("errors.profile.passphrase") %>').show()
$('#teachable_passphrase').addClass('is-invalid')
<% else %>
$('#subscription-modal-content').empty()
  .append('<%= j render partial: "profile/subscriptions_form",
                        locals: { teachable_type: @teachable.class.to_s,
                                  teachable_id: @teachable.id } %>')
<% end %>