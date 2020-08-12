# clean up from previous error messages
$('#username-error').empty().hide()
$('#user_name').removeClass('is-invalid')
$('#js-messages').empty().hide()
$('#accordion').removeClass('border-danger')
$('[id^="course-card-"]').removeClass('border-danger')
$('[id^="user_pass_lecture-"]').removeClass('is-invalid')
$('[id^="passphrase-error-"]').empty()
# display error messages
<% if @errors[:passphrase].present? %>
<% @errors[:passphrase].each do |l| %>
$('#user_pass_lecture\\[' + '<%= l %>' + '\\]').addClass('is-invalid')
$('#passphrase-error-' + '<%= l %>')
  .append('<%= t('errors.profile.passphrase') %>')
$('#course-card-' + '<%= Lecture.find_by_id(l).course.id %>')
  .addClass('border-danger')
$('#collapse-course-<%= Lecture.find_by_id(l).course.id %>').collapse('show')
<% end %>
$('#course-card-' + '<%= Lecture.find_by_id(@errors[:passphrase].first).course.id %>').closest('.programCollapse')
  .collapse('show')
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
