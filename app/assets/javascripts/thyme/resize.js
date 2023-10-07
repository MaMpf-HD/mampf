/**
  Use the methods here to resize thyme players.
*/
const resize = {
  resizeContainer: function(container, factor) {
    const video = document.getElementById('video');
    const $container = $(container);

    let height = $(window).height();
    let width = Math.floor((video.videoWidth * $(window).height() / video.videoHeight) * factor);
    if (width > $(window).width()) {
      const shrink = $(window).width() / width;
      height = Math.floor(height * shrink);
      width = $(window).width();
    }
    const top = Math.floor(0.5 * ($(window).height() - height));
    const left = Math.floor(0.5 * ($(window).width() - width));
    $container.css('height', height + 'px');
    $container.css('width', width + 'px');
    $container.css('top', top + 'px');
    $container.css('left', left + 'px');
  },
};
