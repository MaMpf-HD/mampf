# $ ->
#   loadTwitterSDK()
#   $(document).on 'page:change', renderTimelines
#
# loadTwitterSDK = ->
#   $.getScript "//platform.twitter.com/widgets.js", ->
#     renderTimelines()
#
# renderTimelines = ->
#   $('.twitter-timeline').each ->
#     $container = $(this)
#     widgetId = $container.data 'widget-id'
#     widgetOptions = $container.data 'widget-options'
#     $container.empty()
#     twttr?.widgets.createTimeline widgetId, $container[0], null, widgetOptions
