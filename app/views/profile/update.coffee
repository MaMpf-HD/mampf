# clean up from previous error messages
$('#username-error').empty().hide()
$('#user_name').removeClass('is-invalid')
$('#js-messages').empty().hide()
$('#accordion').removeClass('border-danger')
$('[id^="user_pass_primary_"]').removeClass('is-invalid')
$('[id^="passphrase-error-primary-"]').empty()
$('[id^="course-card-"]').removeClass('border-danger')
$('[id^="user_pass_lecture-"]').removeClass('is-invalid')
$('[id^="passphrase-error-secondary-"]').empty()
# display error messages
<% if @errors[:primary_pass].present? %>
<% @errors[:primary_pass].each do |c| %>
$('#user_pass_primary_' + '<%= c %>').addClass('is-invalid')
$('#passphrase-error-primary-' + '<%= c %>')
  .append('<%= t('errors.profile.passphrase') %>')
$('#course-card-' + '<%= c %>').addClass('border-danger')
<% end %>
<% end %>
<% if @errors[:secondary_pass].present? %>
<% @errors[:secondary_pass].each do |l| %>
$('#user_pass_lecture-' + '<%= l %>').addClass('is-invalid')
$('#passphrase-error-secondary-' + '<%= l %>')
  .append('<%= t('errors.profile.passphrase') %>')
$('#course-card-' + '<%= Lecture.find_by_id(l).course.id %>')
  .addClass('border-danger')
<% end %>
<% end %>
<% if @errors[:courses].present? %>
$('#js-messages').append('<%= @errors[:courses].join("") %>').show()
$('#accordion').addClass('border-danger')
<% end %>
<% if @errors[:name].present? %>
$('#username-error').append('<%= @errors[:name].join("") %>').show()
$('#user_name').addClass('is-invalid')
<% end %>

# scroll to top
$(window).scrollTop(0)
