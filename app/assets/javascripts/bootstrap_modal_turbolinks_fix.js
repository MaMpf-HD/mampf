$(document).on('turbolinks:load', function () {
	// show all active modals
	$('.activeModal').modal('show');
	// remove active status (this needs to be reestablished before caching)
	$('.activeModal').removeClass('activeModal');
});

$(document).on('turbolinks:before-cache', function () {
	// if some modal is open
	if ($('body').hasClass('modal-open')) {
		$('.modal.show').addClass('activeModal');
		$('.modal.show').modal('hide');
		// remove the greyed out background
		$('.modal-backdrop').remove();
	}
});
