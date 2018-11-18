$ ->
  loadMathJax()
  $(document).on 'turbolinks:load', loadMathJax

# make loading mathjax idempotent by storing the state in a data attribute
loadMathJax = ->
  unless $("body").attr('data-has-mathjax') == 'has-mathjax'
    $("body").attr('data-has-mathjax', 'has-mathjax')
    window.MathJax = null
    $.getScript "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS_HTML-full", ->
      MathJax.Hub.Config
        showMathMenu: false
        tex2jax: {inlineMath: [["$","$"],["\\(","\\)"]]}
