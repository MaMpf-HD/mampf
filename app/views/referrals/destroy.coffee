$('#meta-area').empty()
  .append('<%= j render partial: "media/reference",
                        locals: { medium: @medium } %>')
$('#action-placeholder').empty()
$('#action-container').empty()
<% if @medium.referrals.empty? %>
$('#export-references').hide()
<% end %>
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
