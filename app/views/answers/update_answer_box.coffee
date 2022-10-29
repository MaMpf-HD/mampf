$('#answer-box-<%= @answer_id %>').empty().append '<%= ballot_box(@value) %>'
$('#answer-header-<%= @answer_id %>').removeClass('bg-correct')
  .removeClass('bg-incorrect').addClass '<%= bgcolor(@value) %>'
