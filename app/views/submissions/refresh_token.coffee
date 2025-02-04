$('.submissionToken[data-id="<%= @submission.id %>"]')
	.text('<%= @submission.token %>')
$('.clipboardpopup').attr('data-clipboard-text', '<%= @submission.token %>')
$('#refreshTokenButton').blur()