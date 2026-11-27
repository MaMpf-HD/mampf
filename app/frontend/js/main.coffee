$(document).on 'turbo:load', ->

  $(document).on 'click', '.subscriptionSwitch', ->
    $.ajax Routes.toggle_thread_subscription_path(),
      type: 'POST'
      dataType: 'script'
      data: {
        id: $(this).data('id')
        subscribe: $(this).is(':checked')
      }

  $(document).on 'show.bs.collapse', '.subscriptionsCollapse', ->
    $($(this).data('link')).removeClass('text-dark').addClass('text-primary')
    $.ajax Routes.show_accordion_path(),
      type: 'GET'
      dataType: 'script'
      data: {
        id: this.id
      }
     return

  $('.subscriptionsCollapse').on 'hide.bs.collapse', ->
     $($(this).data('link')).removeClass('text-primary').addClass('text-dark')
     return

  return

$(document).on 'turbo:before-cache', ->
  $(document).off 'click', '.subscriptionSwitch'
  $(document).off 'show.bs.collapse', '.subscriptionsCollapse'
  return