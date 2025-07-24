/**
 * Resizes the THYME container to fit the video size and window size.
 *
 * Also see https://stackoverflow.com/a/73425736/
 */
export function resizeThymeContainer(container, factor, offset) {
  const windowWidth = window.innerWidth;
  const windowHeight = window.innerHeight;

  const video = document.getElementById("video");
  const $container = $(container);

  let height = windowHeight;
  const vWidth = video.videoWidth;
  const vHeight = video.videoHeight;
  let width = Math.floor((vWidth * windowHeight / vHeight) * factor) - offset;
  if (width > windowWidth) {
    const shrink = windowWidth / width;
    height = Math.floor(height * shrink);
    width = windowWidth;
  }

  const top = Math.floor(0.5 * (windowHeight - height));
  const left = Math.floor(0.5 * (windowWidth - width));

  $container.css("height", height + "px");
  $container.css("width", width + "px");
  $container.css("top", top + "px");
  $container.css("left", left + "px");
}
