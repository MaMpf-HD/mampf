/*
  All key shortcuts should be bundled here.
*/
var thymeKeyShortcuts = {
  /*
    SHORTCUT LIST:
      Arrow right - plus ten seconds
      Arrow left - minus ten seconds
      f - fullscreen
      Page up - volume up
      Page down - volume down
      m - mute
  */
  addGeneralShortcuts: function() {
    const fullScreenButton = document.getElementById('full-screen');
    const minusTenButton = document.getElementById('minus-ten');
    const muteButton = document.getElementById('mute');
    const plusTenButton = document.getElementById('plus-ten');
    const video = document.getElementById('video');

    window.addEventListener('keydown', function(evt) {
      if (thymeAttributes.lockKeyListeners === true) {
        return;
      }
      const key = evt.key;
      if (key === ' ') {
        if (video.paused === true) {
          video.play();
        } else {
          video.pause();
        }
      } else if (key === 'ArrowRight') {
        $(plusTenButton).trigger('click');
      } else if (key === 'ArrowLeft') {
        $(minusTenButton).trigger('click');
      } else if (key === 'f') {
        $(fullScreenButton).trigger('click');
      } else if (key === 'm') {
        $(muteButton).trigger('click');
      } else if (key === 'PageUp') {
        video.volume = Math.min(video.volume + 0.1, 1);
      } else if (key === 'PageDown') {
        video.volume = Math.max(video.volume - 0.1, 0);
      }
    });
  },

  /*
    Thyme player specific

    SHORTCUT LIST:
      Arrow Up - next chapter
      Arrow Down - previous chapter
      i - toggle interactive area
  */
  addPlayerShortcuts() {
    const iaButton = document.getElementById('ia-active');
    const nextChapterButton = document.getElementById('next-chapter');
    const previousChapterButton = document.getElementById('previous-chapter');

    window.addEventListener('keydown', function(evt) {
      if (thymeAttributes.lockKeyListeners === true) {
        return;
      }
      const key = evt.key;
      if (key === 'i') {
        $(iaButton).trigger('click');
      } else if (key === 'ArrowUp') {
        $(nextChapterButton).trigger('click');
      } else if (key === 'ArrowDown') {
        $(previousChapterButton).trigger('click');
      }
    });
  },

  /*
    Thyme feedback specific

    SHORTCUT LIST:
      q - toggle mistake annotations
      w - toggle presentation annotations
      e - toggle content annotations
      r - toggle note annotations
  */
  addFeedbackShortcuts() {
    const toggleMistakeAnnotations = document.getElementById('toggle-mistake-annotations-check');
    const togglePresentationAnnotations = document.getElementById('toggle-presentation-annotations-check');
    const toggleContentAnnotations = document.getElementById('toggle-content-annotations-check');
    const toggleNoteAnnotations = document.getElementById('toggle-note-annotations-check');

    window.addEventListener('keydown', function(evt) {
      if (thymeAttributes.lockKeyListeners === true) {
        return;
      }
      const key = evt.key;
      if (key === 'q') {
        $(toggleMistakeAnnotations).trigger('click');
      } else if (key === 'w') {
        $(togglePresentationAnnotations).trigger('click');
      } else if (key === 'e') {
        $(toggleContentAnnotations).trigger('click');
      } else if (key === 'r') {
        $(toggleNoteAnnotations).trigger('click');
      }
    });
  },

  /*
    Thyme editor specific
  */
  // Add editor specific keyboard shortcuts here.
};