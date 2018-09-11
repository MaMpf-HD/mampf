$('#screenshot-area').empty()
  .append('<%= j render partial: "media/screenshot",
                        locals: { medium: @medium } %>')
$('#export-screenshot').show()
$('#remove-screenshot').show()
