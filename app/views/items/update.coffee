<% if @errors.present? %>
<% if @errors[:start_time].present? %>
$('#item_start_time').addClass('is-invalid')
$('#start-time-error').empty().append('<%= @errors[:start_time].join(' ') %>')
  .show()
<% end %>
<% else %>
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
<% end %>
