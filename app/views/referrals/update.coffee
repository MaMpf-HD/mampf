# clean up errors from last submission
$('#referral_start_time').removeClass('is-invalid')
$('#start-time-error').empty()
$('#referral_end_time').removeClass('is-invalid')
$('#end-time-error').empty()
$('#referral_link').removeClass('is-invalid')
$('#link-error').empty()
$('#referral_description').removeClass('is-invalid')
$('#description-error').empty()
$('#referral_explanation').removeClass('is-invalid')
$('#explanation-error').empty()
# here come the new error messages
<% if @errors.present? %>
<% if @errors[:start_time].present? %>
$('#referral_start_time').addClass('is-invalid')
$('#start-time-error').append('<%= @errors[:start_time].join(' ') %>')
  .show()
<% end %>
<% if @errors[:end_time].present? %>
$('#referral_end_time').addClass('is-invalid')
$('#end-time-error').append('<%= @errors[:end_time].join(' ') %>')
  .show()
<% end %>
<% if @errors[:link].present? %>
$('#referral_link').addClass('is-invalid')
$('#link-error').append('<%= @errors[:link].join(' ') %>').show()
<% end %>
<% if @errors[:description].present? %>
$('#referral_description').addClass('is-invalid')
$('#description-error').append('<%= @errors[:description].join(' ') %>')
  .show()
<% end %>
<% if @errors[:explanation].present? %>
$('#referral_explanation').addClass('is-invalid')
$('#explanation-error').append('<%= @errors[:explanation].join(' ') %>')
  .show()
<% end %>
<% else %>
$('#meta-area').empty()
  .append('<%= j render partial: "media/reference",
                        locals: { medium: @referral.medium } %>')
metaArea = document.getElementById('meta-area')
renderMathInElement(metaArea, delimiters: [
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
  },
  throwOnError: false
])
# MathJax.Hub.Queue [
#   'Typeset'
#   MathJax.Hub
#   'meta-area'
# ]
metaRef = document.getElementById('<%= "metaref-" + @referral.id.to_s %>')
metaRef.scrollIntoView()
metaRef.style.background = 'lightcyan'
$('#export-references').show()
$('#action-placeholder').empty()
$('#action-container').empty()
setTimeout (->
  metaRef.style.background = 'white'
  return
), 3000
<% end %>
