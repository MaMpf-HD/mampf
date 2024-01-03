/**
  Use the method here to resize thyme players.
*/
// eslint-disable-next-line no-unused-vars
const Resizer = {
  resizeContainer: function (container, factor, offset) {
    const video = document.getElementById("video");
    const $container = $(container);

    let height = $(window).height();
    const vWidth = video.videoWidth;
    const vHeight = video.videoHeight;
    let width = Math.floor((vWidth * $(window).height() / vHeight) * factor) - offset;
    if (width > $(window).width()) {
      const shrink = $(window).width() / width;
      height = Math.floor(height * shrink);
      width = $(window).width();
    }
    const top = Math.floor(0.5 * ($(window).height() - height));
    const left = Math.floor(0.5 * ($(window).width() - width));
    $container.css("height", height + "px");
    $container.css("width", width + "px");
    $container.css("top", top + "px");
    $container.css("left", left + "px");
  },
};
