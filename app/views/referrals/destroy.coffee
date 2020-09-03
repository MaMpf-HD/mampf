# rerender the meta box
$('#meta-area').empty()
  .append('<%= j render partial: "media/reference",
                        locals: { medium: @medium } %>')

# clean up action box
$('#action-placeholder').empty()
$('#action-container').empty()

# hide export references button if the are no referrals
<% if @medium.referrals.empty? %>
$('#export-references').hide()
<% end %>

# rerender math in meta box
metaArea = document.getElementById('meta-area')
renderMathInElement metaArea,
  delimiters: [
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
    }
  ]
  throwOnError: false
