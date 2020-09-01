<% if @success %>
$card = $('.teachableCard[data-type="<%= @teachable.class %>"][data-id="<%= @teachable.id %>"][data-parent="<%= @parent %>"]')
$card.empty()
  .append('<%= j render partial: "main/start/teachable_card",
                        locals: { teachable: @teachable,
                                  current: true,
                                  subscribed: true,
                                  parent: @parent } %>')
$('#subscriptionModal').modal('hide')
<% elsif @unpublished %>
alert('<%= t("admin.lecture.no_rights") %>')
<% else %>
$('#subscriptionModal').modal('show')
<% if @passphrase %>
$('#passphrase-error').text('<%= t("errors.profile.passphrase") %>').show()
$('#teachable_passphrase').addClass('is-invalid')
<% else %>
$('#subscription-modal-content').empty()
  .append('<%= j render partial: "profile/subscriptions_form",
                        locals: { teachable_type: @teachable.class.to_s,
                                  teachable_id: @teachable.id,
                                  parent: @parent } %>')
<% end %>
<% end %>