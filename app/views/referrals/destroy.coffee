$('#meta-area').empty()
  .append('<%= j render partial: "media/reference",
                        locals: { medium: @medium } %>')
$('#action-placeholder').empty()
$('#action-container').empty()
<% if @medium.referrals.empty? %>
$('#export-references').hide()
<% end %>
MathJax.Hub.Queue [
  'Typeset'
  MathJax.Hub
  'meta-area'
]
