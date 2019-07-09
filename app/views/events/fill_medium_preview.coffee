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
<% if @medium.sort == 'Quiz' %>
$cyContainer = $('#cy')
if $cyContainer.length > 0 && $cyContainer.data('type') == 'quiz'
  if $cyContainer.data('linear')
    layout = 'circle'
  else
    layout = 'breadthfirst'
  cy = cytoscape(
    container: $cyContainer
    elements: $cyContainer.data('elements')
    style: [
      {
        selector: 'node'
        style:
          'background-color': 'data(background)'
          'label': 'data(label)'
          'color': 'data(color)'
      }
      {
        selector: 'edge'
        style:
          'width': 3
          'line-color': 'data(color)'
          'curve-style': 'bezier'
          'control-point-distances' : '-50 50 -50'
          'mid-target-arrow-color': 'data(color)'
          'mid-target-arrow-shape': 'triangle'
          'arrow-scale': 2
      }
      {
        selector: '.hovering'
        style:
          'font-size': '2em'
          'background-color': 'green'
          'color': 'green'
      }
      {
        selector: '.selected'
        style:
          'font-size': '2em'
          'background-color': 'green'
          'color': 'green'
      }
    ]
    layout:
      name: layout
      nodeDimensionsIncludeLabels: false
      fit: true
      directed: false)
<% end %>