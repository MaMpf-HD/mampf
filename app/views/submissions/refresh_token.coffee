$('.submissionToken[data-id="<%= @submission.id %>"]')
	.text('<%= @submission.token %>')
$('#refreshTokenButton').blur()