# convert time in seconds to string of the form H:MM:SS
window.secondsToTime = (seconds) ->
  date = new Date(null)
  date.setSeconds seconds
  return date.toISOString().substr(12, 7)

# converts a json timestamp to a double containing the absolute count of millitseconds
window.timestampToMillis = (timestamp) ->
  return 3600 * timestamp.hours + 60 * timestamp.minutes + timestamp.seconds + 0.001 * timestamp.milliseconds

# converts a given integer between 0 and 255 into a hexadecimal, s.t. e.g. "15" becomes "0f"
# (instead of just "f") -> needed for correct format
window.toHexaDecimal = (int) ->
  if int > 15
    return int.toString(16)
  else
    return "0" + int.toString(16)

# lightens up a given color (given in a string in hexadecimal
# representation "#xxyyzz") such that e.g. black becomes dark grey.
# The higher the value of "factor" the brighter the colors become.
window.lightenUp = (color, factor) ->
  red   = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(5, 2))) / factor)
  green = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(3, 2))) / factor)
  blue  = Math.floor(((factor - 1) * 255 + Number("0x" + color.substr(1, 2))) / factor)
  return "#" + toHexaDecimal(blue) + toHexaDecimal(green) + toHexaDecimal(red)

# mixes all colors in the array "colors" (wrtie colors as hexadecimal, e.g. "#1fe67d").
window.colorMixer = (colors) ->
  n = colors.length
  red = 0
  green = 0
  blue = 0
  for i in [0 .. n - 1]
    red += Number("0x" + colors[i].substr(5, 2))
    green += Number("0x" + colors[i].substr(3, 2))
    blue += Number("0x" + colors[i].substr(1, 2))
  red = Math.max(0, Math.min(255, Math.round(red / n)))
  green = Math.max(0, Math.min(255, Math.round(green / n)))
  blue = Math.max(0, Math.min(255, Math.round(blue / n)))
  return "#" + toHexaDecimal(blue) + toHexaDecimal(green) + toHexaDecimal(red)

window.sortAnnotations = (annotations) ->
  if annotations == null
    return
  annotations.sort (ann1, ann2) ->
    timestampToMillis(ann1.timestamp) - timestampToMillis(ann2.timestamp)
  return

window.renderLatex = (element) ->
  renderMathInElement element,
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
  return