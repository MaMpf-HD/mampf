$('#item_link').removeClass('is-invalid')
$('#item-link-error').empty()
$('#item_description').removeClass('is-invalid')
$('#item-description-error').empty()
<% if @errors.present? %>
<% if @errors[:start_time].present? %>
$('#item_start_time').addClass('is-invalid')
$('#start-time-error').empty().append('<%= @errors[:start_time].join(' ') %>')
  .show()
<% end %>
<% if @errors[:link].present? %>
$('#item_link').addClass('is-invalid')
$('#item-link-error').append('<%= @errors[:link].join(' ') %>').show()
<% end %>
<% if @errors[:description].present? %>
$('#item_description').addClass('is-invalid')
$('#item-description-error').append('<%= @errors[:description].join(' ') %>')
  .show()
<% end %>
<% else %>
<% if @from.nil? %>
$('#toc-area').empty()
  .append('<%= j render partial: 'media/toc',
                        locals: { medium: @item.medium } %>')
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'toc-area'
]
tocItem = document.getElementById('<%= "tocitem-" + @item.id.to_s %>')
tocItem.scrollIntoView()
tocItem.style.background = 'lightcyan'
$('#export-toc').show()
$('#action-placeholder').empty()
$('#action-container').empty()
setTimeout (->
  tocItem.style.background = 'white'
  return
), 3000
<% elsif @from == 'referral' %>
$('#newItemModal').modal('hide')
itemSelector = document.getElementById('referral_item_id').selectize
itemSelector.addOption({ value: <%= @item.id %>, text: 'extern <%= @item.description %>'})
itemSelector.refreshOptions()
itemSelector.setValue(<%= @item.id %>)
<% end %>
<% end %>
