<% if @medium %>
$('#mediumPreview').empty()
  .append '<%= j render partial: "media/catalog/medium_preview",
                        locals: { medium: @medium } %>'
mediumPreview = document.getElementById('mediumPreview')
renderMathInElement mediumPreview,
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
<% else %>
$('#mediumPreview').empty()
  .append '<%= t("admin.medium.deleted") %>'
<% end %>