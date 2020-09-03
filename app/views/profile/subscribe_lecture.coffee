<% if @success %>
$card = $('.lectureCard[data-id="<%= @lecture.id %>"][data-parent="<%= @parent %>"]')
$card.empty()
  .append('<%= j render partial: "main/start/lecture_card",
                        locals: { lecture: @lecture,
                                  current: @current,
                                  subscribed: true,
                                  parent: @parent } %>')
$('#subscriptionModal').modal('hide')
<% elsif @unpublished %>
alert('<%= t("admin.lecture.no_rights") %>')
<% else %>
$('#subscriptionModal').modal('show')
<% if @passphrase %>
$('#passphrase-error').text('<%= t("errors.profile.passphrase") %>').show()
$('#lecture_passphrase').addClass('is-invalid')
<% else %>
$('#subscription-modal-content').empty()
  .append('<%= j render partial: "profile/subscriptions_form",
                        locals: { lecture: @lecture,
                                  parent: @parent,
                                  passphrase: @passphrase } %>')
<% end %>
<% end %>