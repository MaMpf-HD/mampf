$(document).on 'turbolinks:load', ->

  $(document).on 'trix-change', '#announcement-details-trix', ->
    $('#announcement-details-preview').html($('#announcement-details-trix').html())
    announcementDetails = document.getElementById('announcement-details-preview')
    renderMathInElement announcementDetails,
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
  return

# clean up everything before turbolinks caches
$(document).on 'turbolinks:before-cache', ->
  $(document).off 'trix-change', '#announcement-details-trix'
  return
