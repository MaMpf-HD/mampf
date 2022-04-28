mediumActions = document.getElementById('mediumActions')
<% if @medium.persisted? %>
$(mediumActions).empty()
  .append '<%= j render partial: "media/catalog/medium_actions",
                        locals: { medium: @medium } %>'
mediumActions.dataset.filled = 'true'
$('#mediumPreview').empty()
  .append '<%= j render partial: "media/catalog/medium_preview",
                        locals: { medium: @medium } %>'
$('#edit_tag_form').hide()
$('#mediumActions').show()
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

editMediumTags = document.getElementById('editMediumTags')
editMediumTags.dataset.medium = <%= @medium.id %>
<% else %>
$(mediumActions).empty()
mediumActions.dataset.filled = 'true'
$('#mediumPreview').empty()
  .append '<%= t("admin.medium.deleted") %>'
<% end %>