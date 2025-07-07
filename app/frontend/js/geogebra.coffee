window.addEventListener 'load', ->
  ggbElement = document.getElementById('ggb-element')
  filename = ggbElement.dataset.filename
  appName = ggbElement.dataset.type
  description = document.getElementById('geogebraDescription')
  renderMathInElement description,
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
    ignoredClasses: ['trix-content']
    throwOnError: false

  ggbApp = new GGBApplet({
    'appName': appName
    'width': 500
    'height': 700
    'showToolBar': false
    'showAlgebraInput': true
    'showMenuBar': false
    'filename': filename
    }, true)

  ggbApp.inject 'ggb-element'
  return