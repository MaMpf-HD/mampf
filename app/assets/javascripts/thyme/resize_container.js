/*
  Use the methods here to resize thyme players.
*/
const resize = {
  resizeContainer: function(container, factor) {
    const video = document.getElementById('video');
    const containerJQ = $('#' + container.id);

    let height = $(window).height();
    let width = Math.floor((video.videoWidth * $(window).height() / video.videoHeight) * factor);
    if (width > $(window).width()) {
      const shrink = $(window).width() / width;
      height = Math.floor(height * shrink);
      width = $(window).width();
    }
    const top = Math.floor(0.5 * ($(window).height() - height));
    const left = Math.floor(0.5 * ($(window).width() - width));
    containerJQ.css('height', height + 'px');
    containerJQ.css('width', width + 'px');
    containerJQ.css('top', top + 'px');
    containerJQ.css('left', left + 'px');
  },
};