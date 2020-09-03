# render screenshot to screenshot area
$('#screenshot-area').empty()
  .append('<%= j render partial: "media/screenshot",
                        locals: { medium: @medium } %>')
# display export and remove buttons
$('#export-screenshot').show()
$('#remove-screenshot').show()
