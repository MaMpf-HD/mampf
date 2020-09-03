mediumActions = document.getElementById('mediumActions')
<% if @medium %>
$(mediumActions).empty()
  .append '<%= j render partial: "clickers/edit/clickerizable_actions",
                        locals: { clicker: @clicker,
                                  question: @question } %>'
mediumActions.dataset.filled = 'true'
$('#mediumPreview').empty()
  .append '<%= j render partial: "quizzes/quizzable_preview",
                        locals: { quizzable: @question } %>'
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

<% else %>
$(mediumActions).empty()
mediumActions.dataset.filled = 'true'
$('#mediumPreview').empty()
  .append '<%= t("admin.medium.deleted") %>'
<% end %>