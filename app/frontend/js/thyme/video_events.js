/**
 * Adds an event listener for the loadedmetadata event on a video element.
 * If the video metadata is already loaded (readyState >= 1), the callback
 * is executed immediately and no event listener is attached. Otherwise,
 * it attaches a one-time event listener that waits for the event to fire.
 */
export function onVideoMetadataLoaded(video, callback) {
  if (video.readyState >= 1) {
    callback();
  }
  else {
    video.addEventListener("loadedmetadata", callback, { once: true });
  }
}

/**
 * Notifies when a track element (chapters, metadata, ...) is ready, i.e. when
 * its cues have been parsed (readyState 2) or parsing has failed (readyState 3).
 *
 * Readiness is tied to the track element itself and not to a single video event,
 * as video events may fire before the track has parsed its cues (notably when
 * the video is already buffered, e.g. under test). Listening to the track's own
 * load/error events as well makes the callbacks fire exactly once, whichever
 * event wins.
 *
 * @param {HTMLTrackElement} track - The track element to watch.
 * @param {function} onReady - Called when the track's cues are available.
 * @param {function} onLoad - Called with a boolean that indicates whether
 * cues are present.
 */
export function onTrackReady(track, onReady, onLoad) {
  let notified = false;

  const notifyIfReady = () => {
    if (notified) {
      return;
    }
    if (track.readyState === 2) {
      notified = true;
      onReady();
      if (onLoad) {
        onLoad(track.track ? (track.track.cues.length > 0) : false);
      }
    }
    else if (track.readyState === 3) {
      notified = true;
      if (onLoad) {
        onLoad(false);
      }
    }
  };

  notifyIfReady();
  track.addEventListener("load", notifyIfReady);
  track.addEventListener("error", notifyIfReady);
  onVideoMetadataLoaded(thymeAttributes.video, notifyIfReady);
  thymeAttributes.video.addEventListener("canplay", notifyIfReady);
}
