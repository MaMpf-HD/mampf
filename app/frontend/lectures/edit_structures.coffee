<% if @erdbeere_error %>
  $('#erdbeereStructuresBody').empty()
  .append('<%= t("erdbeere.error") %>')
<% else %>
$('#erdbeereStructuresBody').empty()
.append('<%= j render partial: "lectures/edit/structures",
                      locals: { lecture: @lecture,
                      					all_structures: @all_structures,
                      					structures: @structures,
                                properties: @properties } %>')
structuresBody = document.getElementById('erdbeereStructuresBody')
renderMathInElement structuresBody,
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

registerErdbeereExampleChanges = ->
  # Erdbeere Examples unsaved changes warning
  $("#lecture-structures-form").on "input", ->
    $("#lecture-erdbeere-examples-warning").show()

  $("#erdbeere-structures-cancel").on "click", ->
    $("#lecture-erdbeere-examples-warning").hide()

initBootstrapPopovers()
registerErdbeereExampleChanges()
<% end %>