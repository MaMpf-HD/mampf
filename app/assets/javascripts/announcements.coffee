$(document).on 'turbo:load', ->

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

# clean up everything before turbo caches
$(document).on 'turbo:before-cache', ->
  $(document).off 'trix-change', '#announcement-details-trix'
  return
