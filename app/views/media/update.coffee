$('#medium_description').removeClass('is-invalid')
$('#medium_external_reference_link').removeClass('is-invalid')
$('#medium-teachable-error').empty()
$('#medium-editors-error').empty()
$('#medium-description-error').empty()
$('#medium-external-reference-error').empty()
<% if @errors[:description].present? %>
$('#medium-description-error').append('<%= @errors[:description].join(" ") %>').show()
$('#medium_description').addClass('is-invalid')
<% end %>
<% if @errors[:external_reference_link].present? %>
$('#medium-external-reference-error')
  .append('<%= @errors[:external_reference_link].join(" ") %>').show()
$('#medium_external_reference_link').addClass('is-invalid')
<% end %>
<% if @errors[:teachable].present? %>
$('#medium-teachable-error')
  .append('<%= @errors[:teachable].last %>').show()
<% end %>
<% if @errors[:editors].present? %>
$('#medium-editors-error')
  .append('<%= @errors[:editors].join(" ") %>').show()
<% end %>
