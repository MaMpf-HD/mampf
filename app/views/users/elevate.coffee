<% if @errors.present? %>
console.log('Hi')
$('#generic_user_name').removeClass('is-invalid')
$('#generic_user_teacher_name').removeClass('is-invalid')
$('#nickname-error').empty()
$('#teachername-error').empty()
<% if @errors[:name].present? %>
$('#generic_user_name').addClass('is-invalid')
$('#nickname-error').append('<%= @errors[:name].join(", ") %>')
<% end %>
<% if @errors[:teacher_name].present? %>
$('#generic_user_teacher_name').addClass('is-invalid')
$('#teachername-error').append('<%= @errors[:teacher_name].join(", ") %>')
<% end %>
<% else %>
location.reload()
<% end %>
