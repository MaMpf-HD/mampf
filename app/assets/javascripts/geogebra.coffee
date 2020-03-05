window.addEventListener 'load', ->
  ggbElement = document.getElementById('ggb-element')
  filename = ggbElement.dataset.filename
  ggbApp = new GGBApplet({
    'appName': 'geometry'
    'width': 800
    'height': 800
    'showToolBar': true
    'showAlgebraInput': true
    'showMenuBar': true
    'filename': filename
    }, true)

  ggbApp.inject 'ggb-element'
  return