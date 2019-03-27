quizzableSelector = document.getElementById('new_vertex_quizzable_select')
if quizzableSelector?
  quizzableSelectize = quizzableSelector.selectize
  quizzableSelectize.clearOptions()
  quizzableSelectize.addOption(<%= raw(@quizzables) %>)
  quizzableSelectize.refreshOptions(false)
  quizzableSelectize.clear()
  quizzableSelectize.refreshOptions(false)
$('#new_vertex_quizzable_select').trigger 'change'
