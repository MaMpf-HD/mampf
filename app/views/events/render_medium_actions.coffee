mediumActions = document.getElementById('mediumActions')
$(mediumActions).empty()
  .append '<%= j render partial: "media/catalog/medium_actions",
                        locals: { medium: @medium } %>'
mediumActions.dataset.filled = 'true'