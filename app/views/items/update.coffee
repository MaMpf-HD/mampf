# clean up from previous error messages
$('#item_link').removeClass('is-invalid')
$('#item-link-error').empty()
$('#item_description').removeClass('is-invalid')
$('#item-description-error').empty()

# display error messages if necessary
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
# no errors occured

<% if @from.nil? %>
# item was updated from within edit item view
# rerender toc box, scroll item into view and colorize it properly
$('#toc-area').empty()
  .append('<%= j render partial: 'media/toc',
                        locals: { medium: @item.medium } %>')
# MathJax.Hub.Queue [
#   'Typeset'
#   MathJax.Hub
#   'toc-area'
# ]
tocArea = document.getElementById('toc-area')
renderMathInElement(tocArea, delimiters: [
  {
    left: '$$'
    right: '$$'
    display: true
  }
  {
    left: '$'
    right: '$'
    display: false
  }
  {
    left: '\\('
    right: '\\)'
    display: false
  }
  {
    left: '\\['
    right: '\\]'
    display: true
  },
  throwOnError: false
])

tocItem = document.getElementById('<%= "tocitem-" + @item.id.to_s %>')
tocItem.scrollIntoView()
tocItem.style.background = 'lightcyan'

# activate export toc button
$('#export-toc').show()

# clean up action box
$('#action-placeholder').empty()
$('#action-container').empty()

# make a nice little fading effect for the item in the toc box
setTimeout (->
  tocItem.style.background = 'white'
  return
), 3000
<% elsif @from == 'referral' %>
# item was created or updated from within referral edit view
# get rid of the modal
$('#newItemModal').modal('hide')

# update item selection field in referral edit view
itemSelector = document.getElementById('referral_item_id').selectize
itemSelector.addOption
  value: <%= @item.id %>
  text: 'extern <%= @item.description %>'
itemSelector.refreshOptions(false)
itemSelector.setValue(<%= @item.id %>)
<% end %>
<% end %>
